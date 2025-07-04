package com.example.demo.dao;

import com.example.demo.dto.EmailAuth;
import org.apache.ibatis.annotations.*;

@Mapper
public interface EmailAuthDao {

    @Insert("""
        INSERT INTO email_auth
        SET email = #{email},
            auth_code = #{authCode},
            created_at = NOW(),
            expired_at = DATE_ADD(NOW(), INTERVAL 3 MINUTE)
        """)
    void insertEmailAuth(@Param("email") String email, @Param("authCode") String authCode);

    @Select("""
        SELECT *
        FROM email_auth
        WHERE email = #{email}
          AND auth_code = #{authCode}
          AND expired_at >= NOW()
        ORDER BY id DESC
        LIMIT 1
        """)
    EmailAuth findValidEmailAuth(@Param("email") String email, @Param("authCode") String authCode);
}
