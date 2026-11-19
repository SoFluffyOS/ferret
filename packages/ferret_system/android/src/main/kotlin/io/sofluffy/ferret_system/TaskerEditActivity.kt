package io.sofluffy.ferret_system

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.text.InputType
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Spinner
import android.widget.TextView

/**
 * Tasker's screen for a Ferret action (the Locale plugin API's
 * `EDIT_SETTING`): pick what to do, the device and the text, link or
 * action. Fields take Tasker variables, such as `%CLIP`.
 */
class TaskerEditActivity : Activity() {
    private lateinit var command: Spinner
    private lateinit var device: EditText
    private lateinit var value: EditText
    private lateinit var body: EditText
    private lateinit var valueLabel: TextView
    private lateinit var bodyLabel: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setTitle(R.string.ferret_system_tasker_title)
        setContentView(buildLayout())
        restore(intent.getBundleExtra(EXTRA_BUNDLE))
    }

    private fun buildLayout(): ScrollView {
        val padding = (resources.displayMetrics.density * 16).toInt()
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(padding, padding, padding, padding)
        }

        command = Spinner(this).apply {
            adapter = ArrayAdapter(
                this@TaskerEditActivity,
                android.R.layout.simple_spinner_dropdown_item,
                COMMAND_LABELS.map { getString(it) },
            )
            onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(parent: AdapterView<*>?, view: android.view.View?, position: Int, id: Long) =
                    updateLabels()

                override fun onNothingSelected(parent: AdapterView<*>?) = Unit
            }
        }
        device = field(R.string.ferret_system_tasker_device_hint)
        valueLabel = label(R.string.ferret_system_tasker_text)
        value = field(R.string.ferret_system_tasker_value_hint)
        bodyLabel = label(R.string.ferret_system_tasker_body)
        body = field(R.string.ferret_system_tasker_value_hint)
        val save = Button(this).apply {
            setText(R.string.ferret_system_tasker_save)
            setOnClickListener { save() }
        }

        column.addView(label(R.string.ferret_system_tasker_command))
        column.addView(command)
        column.addView(label(R.string.ferret_system_tasker_device))
        column.addView(device)
        column.addView(valueLabel)
        column.addView(value)
        column.addView(bodyLabel)
        column.addView(body)
        column.addView(label(R.string.ferret_system_tasker_note))
        column.addView(save, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))
        return ScrollView(this).apply { addView(column) }
    }

    private fun label(text: Int) = TextView(this).apply {
        setText(text)
        setPadding(0, (resources.displayMetrics.density * 12).toInt(), 0, 0)
    }

    private fun field(hint: Int) = EditText(this).apply {
        setHint(hint)
        inputType = InputType.TYPE_CLASS_TEXT
        layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT)
    }

    private fun selectedCommand(): String = TaskerRequest.COMMANDS[command.selectedItemPosition]

    private fun updateLabels() {
        val chosen = selectedCommand()
        val valueText = when (chosen) {
            "open" -> R.string.ferret_system_tasker_link
            "action_run" -> R.string.ferret_system_tasker_action
            "notify" -> R.string.ferret_system_tasker_title_field
            else -> R.string.ferret_system_tasker_text
        }
        valueLabel.setText(valueText)
        val showsValue = chosen != "ring"
        valueLabel.visibility = if (showsValue) TextView.VISIBLE else TextView.GONE
        value.visibility = valueLabel.visibility
        bodyLabel.visibility = if (chosen == "notify") TextView.VISIBLE else TextView.GONE
        body.visibility = bodyLabel.visibility
    }

    private fun restore(bundle: Bundle?) {
        val saved = bundle ?: return updateLabels()
        val index = TaskerRequest.COMMANDS.indexOf(saved.getString(TaskerRequest.KEY_COMMAND))
        if (index >= 0) {
            command.setSelection(index)
        }
        device.setText(saved.getString(TaskerRequest.KEY_DEVICE).orEmpty())
        value.setText(saved.getString(TaskerRequest.KEY_VALUE).orEmpty())
        body.setText(saved.getString(TaskerRequest.KEY_BODY).orEmpty())
        updateLabels()
    }

    private fun save() {
        val chosen = selectedCommand()
        val deviceName = device.text.toString().trim()
        if (chosen != "clipboard_send" && deviceName.isEmpty()) {
            device.error = getString(R.string.ferret_system_tasker_device_needed)
            return
        }

        val bundle = Bundle().apply {
            putString(TaskerRequest.KEY_SECRET, TaskerSecret.get(this@TaskerEditActivity))
            putString(TaskerRequest.KEY_COMMAND, chosen)
            putString(TaskerRequest.KEY_DEVICE, deviceName)
            putString(TaskerRequest.KEY_VALUE, value.text.toString())
            putString(TaskerRequest.KEY_BODY, body.text.toString())
            putString(EXTRA_VARIABLE_REPLACE_KEYS, TaskerRequest.VARIABLE_KEYS.joinToString(" "))
        }
        val commandLabel = getString(COMMAND_LABELS[command.selectedItemPosition])
        val blurb = listOf(commandLabel, deviceName).filter { it.isNotEmpty() }.joinToString(" · ")
        setResult(
            RESULT_OK,
            Intent().putExtra(EXTRA_BUNDLE, bundle).putExtra(EXTRA_BLURB, blurb),
        )
        finish()
    }

    companion object {
        const val ACTION_FIRE_SETTING = "com.twofortyfouram.locale.intent.action.FIRE_SETTING"
        const val EXTRA_BUNDLE = "com.twofortyfouram.locale.intent.extra.BUNDLE"
        const val EXTRA_BLURB = "com.twofortyfouram.locale.intent.extra.BLURB"
        const val EXTRA_VARIABLE_REPLACE_KEYS = "net.dinglisch.android.tasker.extras.VARIABLE_REPLACE_KEYS"

        private val COMMAND_LABELS = listOf(
            R.string.ferret_system_tasker_send_text,
            R.string.ferret_system_tasker_ring,
            R.string.ferret_system_tasker_open,
            R.string.ferret_system_tasker_run_action,
            R.string.ferret_system_tasker_notify,
        )
    }
}
