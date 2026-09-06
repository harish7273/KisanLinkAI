package com.vidhai.payment.dto;
public class CreateOrderResponse {

    private String orderId;

    private Long amount;

    private String currency;

    public CreateOrderResponse() {
    }

    public CreateOrderResponse(
            String orderId,
            Long amount,
            String currency
    ) {
        this.orderId = orderId;
        this.amount = amount;
        this.currency = currency;
    }

    public String getOrderId() {
        return orderId;
    }

    public void setOrderId(String orderId) {
        this.orderId = orderId;
    }

    public Long getAmount() {
        return amount;
    }

    public void setAmount(Long amount) {
        this.amount = amount;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }
}