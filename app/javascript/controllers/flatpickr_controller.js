import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import { Japanese } from "flatpickr/dist/l10n/ja.js"

export default class extends Controller {
    static targets = ["input"]
    static values = {
        mode: String,
        dateFormat: String,
        locale: String
    }

    connect() {
        console.log("Flatpickr controller connected")
        this.initializeFlatpickr()
    }

    initializeFlatpickr() {
        const options = {
            mode: this.modeValue || "single",
            dateFormat: this.dateFormatValue || "Y/m/d",
            allowInput: false,
            clickOpens: true,
            locale: this.localeValue === "ja" ? Japanese : "default"
        }

        // 範囲選択モードの場合の設定
        if (this.modeValue === "range") {
            options.mode = "range"
            options.dateFormat = "Y/m/d"
            options.separator = " 〜 "
        }

        // Flatpickrを初期化
        this.flatpickr = flatpickr(this.inputTarget, options)

        console.log("Flatpickr initialized with options:", options)
    }

    disconnect() {
        if (this.flatpickr) {
            this.flatpickr.destroy()
        }
    }
}