package com.example.demo.service;

import org.springframework.stereotype.Service;

import com.example.demo.dao.GameDao;
import com.example.demo.dto.Player;

@Service
public class GameService {
    
	private GameDao gameDao;
    
	public GameService(GameDao gameDao) {
		this.gameDao = gameDao;
	}

	public Player selectPlayerByMemberId(int memberId) {
		return this.gameDao.selectPlayerByMemberId(memberId);
	}

	
	
    
}