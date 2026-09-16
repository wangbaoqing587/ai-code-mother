package com.wbq.aicodemother.model.dto.user;

import lombok.Data;

import java.io.Serializable;

@Data
public class UserChangePasswordRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    private String userPassword;

    private String newPassword;

    private String checkPassword;
}
