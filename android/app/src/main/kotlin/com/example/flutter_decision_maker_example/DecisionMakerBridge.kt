package com.example.flutter_decision_maker_example

import android.content.Context
import com.google.mediapipe.tasks.decision.DecisionContext
import com.google.mediapipe.tasks.decision.DecisionMaker
import com.google.mediapipe.tasks.decision.DecisionMakerDelegate
import com.google.mediapipe.tasks.decision.DecisionMakerOptions.Companion.decisionMakerOptions

class DecisionMakerBridge(context: Context, modelAssetPath: String, maxTokens: Int) : AutoCloseable {
    private val decisionMaker: DecisionMaker

    init {
        // Use the Kotlin DSL to build options
        val options = decisionMakerOptions {
            modelPath = modelAssetPath
            maxNumTokens = maxTokens
            delegate = DecisionMakerDelegate.CPU
        }
        
        decisionMaker = DecisionMaker.createFromOptions(context, options)
    }

    fun evaluateMultimodalJson(promptText: String, imageBytes: ByteArray, jsonQuestions: String): String {
        // Use the Kotlin data class constructor directly
        val context = DecisionContext(
            text = promptText,
            imageBytes = imageBytes
        )

        return decisionMaker.evaluateJson(context, jsonQuestions)
    }

    override fun close() {
        decisionMaker.close()
    }
}