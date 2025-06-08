import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "count"]

    like(event) {
        event.preventDefault()

        const postId = this.data.get("postId")

        fetch(`/posts/${postId}/likes`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
            }
        })
            .then(response => {
                if (!response.ok) {
                    return response.json().then(data => {
                        throw new Error(data.error || 'Failed to like post');
                    });
                }
                return response.json();
            })
            .then(data => {
                this.updateUI(data)
            })
            .catch(error => {
                console.error('Error:', error.message);
                alert(error.message)
            });
    }

    updateUI(data) {
        // UI更新ロジック
    }
}