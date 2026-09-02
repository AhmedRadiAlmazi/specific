package com.example.mobile

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mouin.app/voice_recorder"
    private var mediaRecorder: MediaRecorder? = null
    private var mediaPlayer: MediaPlayer? = null
    private var currentRecordingPath: String? = null
    private var recordingStartTime: Long = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 200)
                        result.error("PERMISSION_DENIED", "Microphone permission required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val outputDir = cacheDir
                        val audioFile = File.createTempFile("mouin_voice_", ".m4a", outputDir)
                        currentRecordingPath = audioFile.absolutePath

                        mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            MediaRecorder(this)
                        } else {
                            MediaRecorder()
                        }.apply {
                            setAudioSource(MediaRecorder.AudioSource.MIC)
                            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                            setAudioSamplingRate(44100)
                            setAudioEncodingBitRate(96000)
                            setOutputFile(currentRecordingPath)
                            prepare()
                            start()
                        }

                        recordingStartTime = System.currentTimeMillis()
                        result.success(currentRecordingPath)
                    } catch (e: Exception) {
                        mediaRecorder?.release()
                        mediaRecorder = null
                        result.error("RECORDING_FAILED", e.localizedMessage, null)
                    }
                }

                "stopRecording" -> {
                    try {
                        val duration = System.currentTimeMillis() - recordingStartTime
                        mediaRecorder?.apply {
                            stop()
                            release()
                        }
                        mediaRecorder = null

                        val path = currentRecordingPath
                        val file = if (path != null) File(path) else null
                        val size = file?.length() ?: 0

                        result.success(
                            mapOf(
                                "filePath" to (path ?: ""),
                                "durationMs" to duration,
                                "fileSizeBytes" to size
                            )
                        )
                    } catch (e: Exception) {
                        mediaRecorder?.release()
                        mediaRecorder = null
                        result.error("STOP_FAILED", e.localizedMessage, null)
                    }
                }

                "playAudio" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty() || !File(filePath).exists()) {
                        result.error("FILE_NOT_FOUND", "Audio file does not exist", null)
                        return@setMethodCallHandler
                    }

                    try {
                        mediaPlayer?.release()
                        mediaPlayer = MediaPlayer().apply {
                            setDataSource(filePath)
                            prepare()
                            start()
                            setOnCompletionListener {
                                mediaPlayer?.release()
                                mediaPlayer = null
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        mediaPlayer?.release()
                        mediaPlayer = null
                        result.error("PLAYBACK_FAILED", e.localizedMessage, null)
                    }
                }

                "stopAudio" -> {
                    try {
                        mediaPlayer?.stop()
                        mediaPlayer?.release()
                        mediaPlayer = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_PLAYBACK_FAILED", e.localizedMessage, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        mediaRecorder?.release()
        mediaRecorder = null
        mediaPlayer?.release()
        mediaPlayer = null
        super.onDestroy()
    }
}
