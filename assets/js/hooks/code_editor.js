import { EditorView, basicSetup } from "codemirror"
import { EditorState } from "@codemirror/state"
import { elixir } from "codemirror-lang-elixir"
import { oneDark } from "@codemirror/theme-one-dark"
import { keymap } from "@codemirror/view"
import { indentWithTab } from "@codemirror/commands"

export default {
    mounted() {
        this.timer = null
        this.initEditor()
    },

    updated() {
        // Optional: Handle updates from server if needed
    },

    destroyed() {
        if (this.timer) {
            clearTimeout(this.timer)
            this.pushEventTo(this.el, "save_source", {
                source: this.source
            })
        }
    },

    initEditor() {
        const initialContent = this.el.dataset.content
        const isReadOnly = this.el.dataset.readOnly === "true"

        this.editor = new EditorView({
            state: EditorState.create({
                doc: initialContent,
                extensions: [
                    basicSetup,
                    keymap.of([indentWithTab]),
                    elixir(),
                    oneDark,
                    EditorState.readOnly.of(isReadOnly),
                    EditorView.updateListener.of((update) => {
                        if (update.docChanged && !isReadOnly) {
                            this.source = update.state.doc.toString()
                            clearTimeout(this.timer)
                            this.timer = setTimeout(() => {
                                this.pushEventTo(this.el, "save_source", {
                                    source: this.source
                                })
                                this.timer = null
                            }, 1000)
                        }
                    })
                ]
            }),
            parent: this.el
        })
    }
}
