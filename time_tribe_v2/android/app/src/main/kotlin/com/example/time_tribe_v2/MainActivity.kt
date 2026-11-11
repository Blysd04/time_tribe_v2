package com.example.time_tribe_v2

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Màn hình chờ (splash) của Android được hệ thống vẽ TRƯỚC khi Flutter chạy, nên nó chỉ biết
 * chế độ sáng/tối của hệ thống chứ không biết lựa chọn trong app.
 *
 * Từ Android 12 có UiModeManager.setApplicationNightMode: báo cho hệ thống biết app muốn
 * sáng hay tối, hệ thống ghi nhớ và dùng luôn cho splash ở những lần mở sau.
 * Flutter gọi kênh "timetribe/theme" mỗi khi người dùng đổi giao diện.
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "timetribe/theme"
        private const val NATIVE_PREFS = "timetribe_native"
        private const val KEY_APPLIED = "applied_night_mode"
        /** Trùng với AndroidChannelID bên backend và meta-data trong AndroidManifest.xml. */
        private const val NOTIFICATION_CHANNEL_ID = "timetribe_alerts"
        /** Kênh nói chuyện với Flutter để hiện thông báo hệ thống khi app đang mở. */
        private const val NOTIFY_CHANNEL = "timetribe/notify"
        /** Đánh dấu Intent mở app từ thông báo do app tự hiện -> mở tab Thông báo. */
        private const val EXTRA_OPEN_NOTIFICATIONS = "timetribe_open_notifications"
    }

    private var notifyChannel: MethodChannel? = null

    /** App được mở bằng cách bấm vào thông báo (Flutter hỏi một lần lúc khởi động). */
    private var launchedFromNotification = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Phòng khi bản cũ của app chưa kịp báo xuống: đọc lựa chọn Flutter đã lưu
        applyNightMode(readSavedThemeMode())
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        launchedFromNotification =
            intent?.getBooleanExtra(EXTRA_OPEN_NOTIFICATIONS, false) == true
    }

    /** App đang chạy mà người dùng bấm vào thông báo: báo Flutter mở tab Thông báo. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra(EXTRA_OPEN_NOTIFICATIONS, false)) {
            notifyChannel?.invokeMethod("openNotifications", null)
        }
    }

    /**
     * Hiện thông báo hệ thống (thanh thông báo, màn hình khoá, hiện nổi).
     * Firebase KHÔNG tự hiện thông báo khi app đang mở, nên Flutter gọi hàm này cho mỗi tin FCM
     * tới lúc app đang mở. Lúc app chạy nền hoặc đã tắt thì Android tự hiện qua kênh timetribe_alerts.
     */
    private fun showNotification(title: String, body: String) {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        createNotificationChannel()
        val open = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_OPEN_NOTIFICATIONS, true)
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val contentIntent = PendingIntent.getActivity(this, 0, open, piFlags)
        @Suppress("DEPRECATION")
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            Notification.Builder(this)
                .setPriority(Notification.PRIORITY_HIGH)
                .setDefaults(Notification.DEFAULT_ALL)
        }
        builder
            .setSmallIcon(R.drawable.ic_stat_notification)
            .setColor(0xFF3A86FF.toInt())
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setShowWhen(true)
            .setWhen(System.currentTimeMillis())
            .setContentIntent(contentIntent)
        manager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), builder.build())
    }

    /**
     * Kênh thông báo mức cao (IMPORTANCE_HIGH): hiện nổi trên màn hình, có chuông và rung.
     * Thông báo FCM tới lúc app chạy nền do Android tự hiện, nên phải có kênh này
     * (kênh mặc định "Miscellaneous" mức thấp, nhiều máy chỉ để im trong thanh thông báo).
     * Tạo lại nhiều lần không sao, Android giữ nguyên cài đặt người dùng đã chỉnh.
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.notification_channel_description)
            enableVibration(true)
            enableLights(true)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setThemeMode" -> {
                        applyNightMode(call.arguments as? String)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        notifyChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFY_CHANNEL)
            .also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "show" -> {
                            showNotification(
                                call.argument<String>("title") ?: "",
                                call.argument<String>("body") ?: "",
                            )
                            result.success(null)
                        }
                        "launchedFromNotification" -> {
                            result.success(launchedFromNotification)
                            launchedFromNotification = false
                        }
                        else -> result.notImplemented()
                    }
                }
            }
    }

    /** Giá trị ThemeProvider lưu bằng shared_preferences: "light", "dark" hoặc "system". */
    private fun readSavedThemeMode(): String? = try {
        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("flutter.settings.theme_mode", null)
    } catch (e: Exception) {
        null
    }

    private fun applyNightMode(mode: String?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val target = when (mode) {
            "light" -> UiModeManager.MODE_NIGHT_NO
            "dark" -> UiModeManager.MODE_NIGHT_YES
            else -> UiModeManager.MODE_NIGHT_AUTO // theo hệ thống
        }
        val prefs = getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        if (prefs.getInt(KEY_APPLIED, -1) == target) return
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager ?: return
        try {
            uiModeManager.setApplicationNightMode(target)
            prefs.edit().putInt(KEY_APPLIED, target).apply()
        } catch (e: Exception) {
            // Một số ROM chặn API này, splash vẫn theo hệ thống như cũ
        }
    }
}
