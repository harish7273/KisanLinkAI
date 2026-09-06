package com.vidhai.payment.dto;

public class CreateOrderRequest {

    private Long amount;

    private String receipt;

    public CreateOrderRequest() {
    }

    public Long getAmount() {
        return amount;
    }

    public void setAmount(Long amount) {
        this.amount = amount;
    }

    public String getReceipt() {
        return receipt;
    }

    public void setReceipt(String receipt) {
        this.receipt = receipt;
    }
}