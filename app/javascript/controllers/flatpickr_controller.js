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

        const toYearNumber = (value) => {
            if (!value) return null
            if (value instanceof Date) return value.getFullYear()
            if (typeof value === "object" && value.dateObj instanceof Date) {
                return value.dateObj.getFullYear()
            }
            return null
        }

        const ensureMonthDropdownStyling = (element) => {
            if (!element) return
            element.setAttribute("aria-label", element.getAttribute("aria-label") || "月を選択")
        }

        const buildYearOptions = (dropdown, minYear, maxYear, currentYear) => {
            const selectedValue = String(currentYear)
            dropdown.innerHTML = ""

            for (let year = maxYear; year >= minYear; year -= 1) {
                const option = document.createElement("option")
                option.value = String(year)
                option.textContent = `${year}年`
                if (option.value === selectedValue) {
                    option.selected = true
                }
                dropdown.appendChild(option)
            }
        }

        const ensureYearDropdown = (instance, currentMonth, yearWrapper) => {
            if (!instance || !currentMonth || !yearWrapper) return

            let minYear = toYearNumber(instance.config.minDate)
            let maxYear = toYearNumber(instance.config.maxDate)
            const currentYear = instance.currentYear

            if (typeof minYear !== "number") {
                minYear = currentYear - 5
            }
            if (typeof maxYear !== "number") {
                maxYear = currentYear + 5
            }

            if (currentYear < minYear) minYear = currentYear - 1
            if (currentYear > maxYear) maxYear = currentYear + 1

            let dropdown = currentMonth.querySelector("select.flatpickr-yearDropdown")
            if (!dropdown) {
                dropdown = document.createElement("select")
                dropdown.classList.add("flatpickr-yearDropdown")
                dropdown.setAttribute("aria-label", "年を選択")
                dropdown.addEventListener("change", (event) => {
                    const selectedYear = parseInt(event.target.value, 10)
                    if (!Number.isNaN(selectedYear) && selectedYear !== instance.currentYear) {
                        instance.changeYear(selectedYear)
                    }
                })
                currentMonth.insertBefore(dropdown, currentMonth.firstChild)
            }

            if (!dropdown.classList.contains("flatpickr-monthDropdown-months")) {
                dropdown.classList.add("flatpickr-monthDropdown-months")
            }

            const storedRange = dropdown.dataset.yearRange ? dropdown.dataset.yearRange.split(":") : null
            const [storedMin, storedMax] = storedRange ? storedRange.map((value) => parseInt(value, 10)) : []

            if (storedMin !== minYear || storedMax !== maxYear) {
                buildYearOptions(dropdown, minYear, maxYear, currentYear)
                dropdown.dataset.yearRange = `${minYear}:${maxYear}`
            } else {
                dropdown.value = String(currentYear)
            }

            dropdown.value = String(currentYear)

            yearWrapper.style.display = "none"
            yearWrapper.setAttribute("aria-hidden", "true")
        }

        const reorderHeader = (instance) => {
            const calendar = instance?.calendarContainer
            if (!calendar) return

            const currentMonth = calendar.querySelector(".flatpickr-current-month")
            if (!currentMonth) return

            const yearWrapper = currentMonth.querySelector(".numInputWrapper")
            const monthDropdown = Array.from(currentMonth.querySelectorAll(".flatpickr-monthDropdown-months"))
                .find((element) => !element.classList.contains("flatpickr-yearDropdown"))
            const monthLabel = currentMonth.querySelector(".cur-month")

            ensureYearDropdown(instance, currentMonth, yearWrapper)
            ensureMonthDropdownStyling(monthDropdown)

            if (monthLabel) {
                monthLabel.style.display = monthDropdown ? "none" : ""
            }

            if (monthDropdown) {
                currentMonth.appendChild(monthDropdown)
            } else if (monthLabel) {
                currentMonth.appendChild(monthLabel)
            }
        }

        const addHook = (hookName, fn) => {
            const existing = options[hookName]
            if (Array.isArray(existing)) {
                options[hookName] = [...existing, fn]
            } else if (existing) {
                options[hookName] = [existing, fn]
            } else {
                options[hookName] = [fn]
            }
        }

        const headerHook = (selectedDates, dateStr, instance) => reorderHeader(instance)
        addHook("onReady", headerHook)
        addHook("onMonthChange", headerHook)
        addHook("onYearChange", headerHook)

        // Flatpickrを初期化
        this.flatpickr = flatpickr(this.inputTarget, options)

        reorderHeader(this.flatpickr)

        console.log("Flatpickr initialized with options:", options)
    }

    disconnect() {
        if (this.flatpickr) {
            this.flatpickr.destroy()
        }
    }
}
