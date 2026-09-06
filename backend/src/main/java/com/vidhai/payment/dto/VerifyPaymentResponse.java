package com.vidhai.payment.dto;

public class VerifyPaymentResponse {

    private boolean verified;
    private String message;

    public VerifyPaymentResponse() {
    }

    public VerifyPaymentResponse(boolean verified, String message) {
        this.verified = verified;
        this.message = message;
    }

    public boolean isVerified() {
        return verified;
    }

    public void setVerified(boolean verified) {
        this.verified = verified;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
