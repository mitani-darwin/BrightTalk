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
                longhand: [
                    "1月", "2月", "3月", "4月", "5月", "6月",
                    "7月", "8月", "9月", "10月", "11月", "12月"
                ],
                shorthand: [
                    "1月", "2月", "3月", "4月", "5月", "6月",
                    "7月", "8月", "9月", "10月", "11月", "12月"
                ]
            },
            yearAriaLabel: "年",
            monthAriaLabel: "月"
        }

        const options = {
            mode: this.modeValue || "single",
            dateFormat: this.dateFormatValue || "Y/m/d",
            locale: customJapanese,
            allowInput: false,
            showMonths: 1,
            monthSelectorType: "dropdown",
            onReady: function(selectedDates, dateStr, instance) {
                const yearInput = instance.currentYearElement
                const wrapper = yearInput.parentNode

                // input を削除
                wrapper.innerHTML = ""

                // 現在の年
                const thisYear = new Date().getFullYear()

                // セレクトを作成（今年 ±5年）
                const select = document.createElement("select")
                select.className = "flatpickr-yearDropdown"

                for (let y = thisYear - 5; y <= thisYear + 5; y++) {
                    const option = document.createElement("option")
                    option.value = y
                    option.textContent = `${y}年`
                    if (y === instance.currentYear) option.selected = true
                    select.appendChild(option)
                }

                // 年を切り替えたら flatpickr に反映
                select.addEventListener("change", (e) => {
                    instance.changeYear(parseInt(e.target.value, 10))
                })

                wrapper.appendChild(select)
            }
        }

        if (this.modeValue === "range") {
            options.mode = "range"
            options.dateFormat = "Y/m/d"
        }

        this.flatpickr = flatpickr(this.inputTarget, options)
    }

    disconnect() {
        if (this.flatpickr) {
            this.flatpickr.destroy()
        }
    }
}