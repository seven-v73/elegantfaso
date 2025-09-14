// Chemin : android/app/src/main/kotlin/com/example/faso_style/MyFirebaseMessagingService.kt
package com.example.faso_style

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        // Envoyer le token à votre serveur
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // Créer le canal de notification
        createNotificationChannel()

        // Construire la notification
        val notificationBuilder = NotificationCompat.Builder(this, "high_importance_channel")
            .setContentTitle(remoteMessage.notification?.title)
            .setContentText(remoteMessage.notification?.body)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Icône temporaire
            .setAutoCancel(true)

        // Afficher la notification
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(0, notificationBuilder.build())
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "high_importance_channel",
                "Notifications importantes",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "Notifications importantes de l'application"
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}