package com.example.demo.service;

import org.springframework.stereotype.Service;

import com.example.demo.dao.CustomCharacterDao;

@Service
public class CustomCharacterService {
    
	private CustomCharacterDao customCharacterDao;
    
	public CustomCharacterService(CustomCharacterDao customCharacterDao) {
		this.customCharacterDao = customCharacterDao;
	}

	public void customCaracterBySave(int memberId, String skin_face, String hair, String top, String bottom, String dress, String shoes, String accessory) {
		this.customCharacterDao.customCaracterBySave(memberId, skin_face, hair, top, bottom, dress, shoes, accessory);
	}

	public void customCaracterByUpdate(int memberId, String skin_face, String hair, String top, String bottom, String dress, String shoes, String accessory) {
		this.customCharacterDao.customCaracterByUpdate(memberId, skin_face, hair, top, bottom, dress, shoes, accessory);
	}

	public boolean exists(int memberId) {
		return customCharacterDao.existsByMemberId(memberId);
	}
    
}