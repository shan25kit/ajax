package com.example.demo.dao;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import com.example.demo.dto.CustomCharacter;

@Mapper
public interface CustomCharacterDao {

	    @Insert("""
	    		INSERT INTO custom_character
	    			SET memberId = #{memberId}
	    				, skinColor = #{skinColor}
		    		    , hair = #{hair}
		    		    , hairColor = #{hairColor}
		    		    , top = #{top}
		    		    , bottom = #{bottom}
		    		    , dress = #{dress}
		    		    , shoes = #{shoes}
		    		    , accessory = #{accessory}
	    		""")
		void customCaracterBySave(int memberId, String skinColor, Integer hair, String hairColor, Integer top, Integer bottom, Integer dress, Integer shoes, Integer accessory);
	    
	    @Update("""
		        UPDATE custom_character
		    		SET skinColor = #{skinColor}
		    		    , hair = #{hair}
		    		    , hairColor = #{hairColor}
		    		    , top = #{top}
		    		    , bottom = #{bottom}
		    		    , dress = #{dress}
		    		    , shoes = #{shoes}
		    		    , accessory = #{accessory}
		    		WHERE memberId = #{memberId}
	    		""")
		void customCaracterByUpdate(int memberId, String skinColor, Integer hair, String hairColor, Integer top, Integer bottom, Integer dress, Integer shoes, Integer accessory);

	    @Select("""
	    		SELECT COUNT(*) > 0 
	    			FROM custom_character 
	    			WHERE memberId = #{memberId}
	    		""")
		boolean existsByMemberId(int memberId);


		CustomCharacter getCharacterByMemberId(int memberId);

}