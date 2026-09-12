package com.example.invoiceandbilling

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "mix_and_sip_printing/bluetooth"
    private val permissionRequestCode = 4102
    private val serialPortUuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val executor = Executors.newSingleThreadExecutor()

    private var printerSocket: BluetoothSocket? = null
    private var printerOutput: OutputStream? = null
    private var connectedPrinterAddress: String? = null

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingPermissionAction: (() -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result -> handleMethod(call, result) }
    }

    override fun onDestroy() {
        closePrinterConnection()
        executor.shutdownNow()
        super.onDestroy()
    }

    private fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSavedPrinter" -> result.success(preferences().getString("printer_address", null))
            "savePrinter" -> {
                val address = call.argument<String>("address")
                preferences().edit().putString("printer_address", address).apply()
                result.success(null)
            }
            "getBondedDevices" -> withBluetoothPermission(result) { returnBondedDevices(result) }
            "printBytes" -> withBluetoothPermission(result) { printBytes(call, result) }
            else -> result.notImplemented()
        }
    }

    private fun preferences() = getSharedPreferences("mix_and_sip_pos", Context.MODE_PRIVATE)

    private fun bluetoothAdapter(): BluetoothAdapter? {
        val manager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        return manager.adapter
    }

    private fun withBluetoothPermission(result: MethodChannel.Result, action: () -> Unit) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        ) {
            action()
            return
        }

        if (pendingPermissionResult != null) {
            result.error("PERMISSION_BUSY", "A Bluetooth permission request is already in progress.", null)
            return
        }

        pendingPermissionResult = result
        pendingPermissionAction = action
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.BLUETOOTH_CONNECT),
            permissionRequestCode
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != permissionRequestCode) return

        val result = pendingPermissionResult
        val action = pendingPermissionAction
        pendingPermissionResult = null
        pendingPermissionAction = null

        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            action?.invoke()
        } else {
            result?.error("BLUETOOTH_PERMISSION_DENIED", "Bluetooth permission is required to print.", null)
        }
    }

    private fun returnBondedDevices(result: MethodChannel.Result) {
        val adapter = bluetoothAdapter()
        if (adapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "This device does not support Bluetooth.", null)
            return
        }
        if (!adapter.isEnabled) {
            result.error("BLUETOOTH_OFF", "Turn on Bluetooth and try again.", null)
            return
        }

        val devices = adapter.bondedDevices
            .map { mapOf("name" to (it.name ?: "Bluetooth device"), "address" to it.address) }
            .sortedBy { it["name"]?.lowercase() }
        result.success(devices)
    }

    private fun printBytes(call: MethodCall, result: MethodChannel.Result) {
        val address = call.argument<String>("address")
        val values = call.argument<List<Int>>("bytes")
        if (address.isNullOrBlank() || values == null) {
            result.error("INVALID_PRINT_JOB", "Printer address and receipt bytes are required.", null)
            return
        }

        val adapter = bluetoothAdapter()
        if (adapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "This device does not support Bluetooth.", null)
            return
        }
        if (!adapter.isEnabled) {
            result.error("BLUETOOTH_OFF", "Turn on Bluetooth and try again.", null)
            return
        }

        val bytes = values.map { it.toByte() }.toByteArray()
        executor.execute {
            try {
                connectAndWrite(adapter.getRemoteDevice(address), bytes)
                runOnUiThread { result.success(null) }
            } catch (error: Exception) {
                val message = if (error is IllegalArgumentException) {
                    "The saved printer address is invalid."
                } else {
                    error.message ?: "Unable to connect to the printer."
                }
                runOnUiThread { result.error("PRINT_FAILED", message, null) }
            }
        }
    }

    private fun connectAndWrite(device: BluetoothDevice, bytes: ByteArray) {
        if (connectedPrinterAddress == device.address && printerOutput != null) {
            try {
                writeReceipt(printerOutput!!, bytes)
                return
            } catch (_: IOException) {
                // The printer may have dropped an idle connection. Reconnect below.
                closePrinterConnection()
            }
        } else {
            closePrinterConnection()
        }

        var lastError: Exception? = null
        val socketFactories = listOf(
            { device.createInsecureRfcommSocketToServiceRecord(serialPortUuid) },
            { device.createRfcommSocketToServiceRecord(serialPortUuid) }
        )

        for (factory in socketFactories) {
            val socket = factory()
            try {
                socket.connect()
                val output = socket.outputStream
                printerSocket = socket
                printerOutput = output
                connectedPrinterAddress = device.address
                writeReceipt(output, bytes)
                return
            } catch (error: IOException) {
                lastError = error
                try {
                    socket.close()
                } catch (_: IOException) {
                    // Preserve the original connection error.
                }
            }
        }
        throw lastError ?: IOException("Unable to connect to the selected printer.")
    }

    private fun writeReceipt(output: OutputStream, bytes: ByteArray) {
        var offset = 0
        while (offset < bytes.size) {
            val count = minOf(256, bytes.size - offset)
            output.write(bytes, offset, count)
            offset += count
            if (offset < bytes.size) Thread.sleep(10)
        }
        output.flush()
    }

    private fun closePrinterConnection() {
        try {
            printerOutput?.close()
        } catch (_: IOException) {
            // The connection is already unavailable.
        }
        try {
            printerSocket?.close()
        } catch (_: IOException) {
            // The connection is already unavailable.
        }
        printerOutput = null
        printerSocket = null
        connectedPrinterAddress = null
    }
}
