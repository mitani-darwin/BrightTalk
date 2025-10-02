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
        const customJapanese = {
            ...Japanese,
            months: {
                ...Japanese.months,
                // 月の表示順序を年月順に調整
                longhand: [
                    "1月", "2月", "3月", "4月", "5月", "6月",
                    "7月", "8月", "9月", "10月", "11月", "12月"
                ],
                shorthand: [
                    "1月", "2月", "3月", "4月", "5月", "6月",
                    "7月", "8月", "9月", "10月", "11月", "12月"
                ]
            },
            // 年月の表示順序をカスタマイズ
            yearAriaLabel: "年",
            monthAriaLabel: "月"
        }

        const options = {
            mode: this.modeValue || "single",
            dateFormat: this.dateFormatValue || "Y/m/d",
            locale: customJapanese,
            allowInput: false,
            // 年月選択の順序を制御
            showMonths: 1,
            monthSelectorType: "dropdown",
            yearSelectorType: "dropdown"
        }

        if (this.modeValue === "range") {
            options.mode = "range"
            options.dateFormat = "Y/m/d"  // YYをYに修正
            // 無効な設定を削除
            // options.flex-direction = "row-reverse"  // これは無効な設定
        }

        this.flatpickr = flatpickr(this.inputTarget, options)
    }

    disconnect() {
        if (this.flatpickr) {
            this.flatpickr.destroy()
        }
    }
}