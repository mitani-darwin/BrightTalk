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
        this.waitForFlatpickrAndInitialize()
    }

    disconnect() {
        if (this.flatpickrInstance) {
            this.flatpickrInstance.destroy()
        }
    }

    async waitForFlatpickrAndInitialize() {
        // flatpickrが利用可能になるまで待機
        let attempts = 0;
        const maxAttempts = 50; // 最大5秒間待機 (50 * 100ms)

        while (typeof window.flatpickr === 'undefined' && attempts < maxAttempts) {
            await new Promise(resolve => setTimeout(resolve, 100));
            attempts++;
        }

        if (typeof window.flatpickr === 'undefined') {
            console.error('Flatpickr failed to load after 5 seconds');
            return;
        }

        this.initializeFlatpickr();
    }

    initializeFlatpickr() {
        const options = {
            mode: "range",
            dateFormat: this.dateFormatValue || "Y/m/d",
            locale: Japanese,
            allowInput: true,
            clickOpens: true,
            conjunction: " から "
        }

        this.flatpickrInstance = flatpickr(this.inputTarget, options)

        this.flatpickrInstance.config.onChange.push((selectedDates, dateStr, instance) => {
            console.log("Date selected:", dateStr)
        })
    }
}