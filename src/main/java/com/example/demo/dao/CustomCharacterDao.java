package com.example.demo.dao;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import com.example.demo.dto.CustomCharacterDto;
import com.example.demo.dto.Member;
import com.example.demo.dto.Player;

@Mapper
public interface CustomCharacterDao {

	    @Insert("""
	    		INSERT INTO custom_character
	    			SET memberId = #{memberId}
	    				, skin_face = #{skin_face}
	    				, hair = #{hair}
	    				, top = #{top}
	    				, bottom = #{bottom}
	    				, dress = #{dress}
	    				, shoes = #{shoes}
	    				, accessory = #{accessory}
	    		""")
		void customCaracterBySave(int memberId, String skin_face, String hair, String top, String bottom, String dress, String shoes, String accessory);

	    @Update("""
		        UPDATE custom_character
		    		SET skin_face = #{skin_face}
		    		    , hair = #{hair}
		    		    , top = #{top}
		    		    , bottom = #{bottom}
		    		    , dress = #{dress}
		    		    , shoes = #{shoes}
		    		    , accessory = #{accessory}
		    		WHERE memberId = #{memberId}
	    		""")
		void customCaracterByUpdate(int memberId, String skin_face, String hair, String top, String bottom, String dress, String shoes, String accessory);

	    @Select("""
	    		SELECT COUNT(*) > 0 
	    			FROM custom_character 
	    			WHERE memberId = #{memberId}
	    		""")
		boolean existsByMemberId(int memberId);

}