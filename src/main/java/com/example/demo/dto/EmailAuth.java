package com.example.demo.dto;

import java.time.LocalDateTime;

import lombok.Data;

@Data
public class EmailAuth {
    private int id;
    private String email;
    private String authCode;
    private LocalDateTime createdAt;
    private LocalDateTime expiredAt;
}