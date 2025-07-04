package com.example.demo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import com.example.demo.dto.Member;
import com.example.demo.dto.Player;

@Mapper
public interface GameDao {

	@Select("""
		    SELECT *
		    FROM player p
		    LEFT JOIN  memberInfo mi
		    ON p.memberId = mi.memberId
		    WHERE p.memberId = #{memberId}
		    """)
	Player selectPlayerByMemberId(int memberId);


}