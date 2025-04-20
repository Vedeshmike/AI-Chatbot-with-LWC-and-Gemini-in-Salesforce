import { LightningElement, track } from 'lwc';
import askOpenAI from '@salesforce/apex/OpenAIAgent.askOpenAI';

export default class ChatBot extends LightningElement {
    @track messages = [];
    @track isLoading = false;

    // Scroll chat to bottom
    scrollToBottom() {
        setTimeout(() => {
            const chatContainer = this.template.querySelector('.chat-container');
            if (chatContainer) {
                chatContainer.scrollTop = chatContainer.scrollHeight;
            }
        }, 100);
    }
    
    // Call this method after messages are updated
    handleNewMessage() {
        this.scrollToBottom();
    }

    // Handle sending message
    sendMessage() {
        let inputField = this.template.querySelector('[data-input]');
        let userText = inputField.value.trim();
        if (!userText) return;

        // Add user message
        this.messages.push({ id: Date.now(), text: userText, cssClass: 'user-message' });
        inputField.value = '';
        this.isLoading = true;
        this.scrollToBottom();

        // Call Apex
        askOpenAI({ userQuery: userText })
            .then(response => {
                this.messages.push({ id: Date.now(), text: response, cssClass: 'bot-message' });
                this.scrollToBottom();
            })
            .catch(error => {
                console.error('Error:', error);
                this.messages.push({ id: Date.now(), text: 'Error: Unable to fetch response.', cssClass: 'bot-message' });
            })
            .finally(() => {
                this.isLoading = false;
                this.scrollToBottom();
            });
    }

    // Send message on Enter key press
    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.sendMessage();
        }
    }
}