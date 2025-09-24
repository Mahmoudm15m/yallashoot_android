package com.syrialive.app

import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import okhttp3.*
import java.io.IOException
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec
import kotlin.random.Random

class MainActivity: FlutterActivity() {
    private val OSTORA_CHANNEL = "com.syrialive.app/ostora_api"
    private val aesKeyHex = "4e5c6d1a8b3fe8137a3b9df26a9c4de195267b8e6f6c0b4e1c3ae1d27f2b4e6f"
    private val ivHex = "a9c21f8d7e6b4a9db12e4f9d5c1a7b8e"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OSTORA_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "fetchOData") {
                val endpoint = call.argument<String>("endpoint")
                if (endpoint == null) {
                    result.error("INVALID_ARGUMENT", "Endpoint cannot be null", null)
                    return@setMethodCallHandler
                }
                fetchOstoraDataFromNative(endpoint, result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun fetchOstoraDataFromNative(endpoint: String, result: MethodChannel.Result) {
        val client = OkHttpClient()
        val randomSubdomain = generateRandomString()
        val url = "https://${randomSubdomain}.s-25.shop/api/v6.2/$endpoint"

        val request = Request.Builder().url(url).build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                runOnUiThread {
                    result.error("NETWORK_ERROR", "Failed to fetch data from native", e.message)
                }
            }

            override fun onResponse(call: Call, response: Response) {
                val responseBody = response.body?.string()
                if (response.isSuccessful && responseBody != null) {
                    try {
                        // الآن نستدعي دالة فك التشفير المكتوبة بـ Kotlin
                        val decodedData = decodeResponse(responseBody)
                        runOnUiThread {
                            result.success(decodedData)
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("DECODING_ERROR", "Failed to decode response", e.message)
                        }
                    }
                } else {
                    runOnUiThread {
                        result.error("HTTP_ERROR", "Failed with status code: ${response.code}", null)
                    }
                }
            }
        })
    }

    // ==========================================================
    // ==== تمت ترجمة الدوال من Dart إلى Kotlin هنا ====
    // ==========================================================

    /**
     * ترجمة لدالة generateRandomString من Dart
     */
    private fun generateRandomString(length: Int = 10): String {
        val charPool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return (1..length)
            .map { Random.nextInt(0, charPool.length).let { charPool[it] } }
            .joinToString("")
    }

    /**
     * ترجمة لدالة decodeResponse من Dart باستخدام مكتبات التشفير في أندرويد
     */
    private fun decodeResponse(ciphertext: String): String {
        // تحويل المفتاح والـ IV من Hex إلى ByteArray
        val keyBytes = hexToByteArray(aesKeyHex)
        val ivBytes = hexToByteArray(ivHex)

        // فك تشفير النص من Base64
        val encryptedBytes = Base64.decode(ciphertext, Base64.DEFAULT)

        // إعداد عملية فك التشفير AES/CBC/NoPadding
        // نستخدم NoPadding لأننا سنقوم بإزالة الحشو يدويًا كما في كود Dart
        val cipher = Cipher.getInstance("AES/CBC/NoPadding")
        val keySpec = SecretKeySpec(keyBytes, "AES")
        val ivSpec = IvParameterSpec(ivBytes)
        cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec)

        // القيام بفك التشفير
        val decryptedBytes = cipher.doFinal(encryptedBytes)

        // --- تطبيق نفس منطق إزالة الحشو (Padding) المستخدم في Dart ---
        if (decryptedBytes.isEmpty()) {
            return ""
        }

        val padLen = decryptedBytes.last().toInt()

        // إذا كانت قيمة الحشو غير منطقية، نُرجع النص كما هو
        if (padLen > 16 || padLen <= 0) {
            return String(decryptedBytes, Charsets.UTF_8)
        }

        // التحقق من أن طول البيانات أكبر من قيمة الحشو
        if (decryptedBytes.size < padLen) {
            return String(decryptedBytes, Charsets.UTF_8)
        }

        // إزالة الحشو
        val unpaddedBytes = decryptedBytes.copyOfRange(0, decryptedBytes.size - padLen)

        return String(unpaddedBytes, Charsets.UTF_8)
    }

    /**
     * دالة مساعدة لتحويل نص سداسي عشري (Hex) إلى ByteArray
     */
    private fun hexToByteArray(hex: String): ByteArray {
        check(hex.length % 2 == 0) { "Must have an even length" }
        return hex.chunked(2)
            .map { it.toInt(16).toByte() }
            .toByteArray()
    }
}