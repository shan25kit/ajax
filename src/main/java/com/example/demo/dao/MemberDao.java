package com.example.demo.dao;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import com.example.demo.dto.Member;

@Mapper
public interface MemberDao {

	@Insert("""
			INSERT INTO `member`
				SET regDate = NOW()
					, updateDate = NOW()
					, loginType = #{loginType}
					, email = #{email}
					, loginId = #{loginId}
					, loginPw = #{loginPw}
			""")
	void signupMember(String loginType, String email, String loginId, String loginPw);

	@Select("""
			SELECT LAST_INSERT_ID()
			""")
	int getLastInsertId();

	@Select("""
			SELECT mi.*, m.*
			 FROM memberInfo mi
			 RIGHT JOIN `member` m
			 ON mi.memberId = m.id
			 WHERE loginId = #{loginId}
			""")
	Member getMemberByLoginId(String loginId);

	@Select("""
			SELECT *
				FROM `member` m
				LEFT JOIN memberInfo mi
				ON m.id = mi.memberId
				WHERE email = #{email}
			""")
	Member getMemberByEmail(String email);

	@Select("""
			SELECT nickName
				FROM `member`
				WHERE id = #{id}
			""")
	String getLoginId(int id);

	@Update("""
			UPDATE `member`
				SET updateDate = NOW()
					, loginPw = #{loginPw}
				WHERE id = #{loginedMemberId}
			""")
	void modifyPassword(int loginedMemberId, String loginPw);

	@Insert("""
			INSERT INTO `member`
				SET regDate = NOW()
					, updateDate = NOW()
					, email = #{email}
					, loginId = #{loginId}
					, loginPw = #{loginPw}
			""")
	void emailSignUp(String email, String loginId, String loginPw);

	@Insert("""
			INSERT INTO memberInfo
			 	SET memberId = #{memberId}
			 		, nickName = #{nickName}
			""")
	void insertNickName(int memberId, String nickName);

	@Select("""
			SELECT mi.*
			    FROM memberInfo mi
			    INNER JOIN `member` m
			    ON mi.memberId = m.id
			    WHERE mi.nickName = #{nickName}
			""")
	Member getMemberByNickName(String nickName);

	
	@Select("""
			SELECT *
				FROM member
				WHERE loginId = #{loginId}
			""")
	Member getMemberByLoginIdChk(String loginId);

	@Select("""
			SELECT mi.*, m.*
			 FROM memberInfo mi
			 RIGHT JOIN `member` m
			 ON mi.memberId = m.id
			 WHERE m.id = #{id}
			""")
	Member getMemberById(int id);

	@Update("""
			UPDATE `memberInfo`
			 	SET nickName = #{nickName}
			 	WHERE memberId = #{memberId}
			""")
	void updateNickName(int memberId, String nickName);

}

