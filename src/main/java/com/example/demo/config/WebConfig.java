package com.example.demo.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import com.example.demo.interceptor.BeforeActionInterceptor;
import com.example.demo.interceptor.NeedLoginInterceptor;
import com.example.demo.interceptor.NeedLogoutInterceptor;

@Configuration
public class WebConfig implements WebMvcConfigurer {

	private BeforeActionInterceptor beforeActionInterceptor;
	private NeedLoginInterceptor needLoginInterceptor;
	private NeedLogoutInterceptor needLogoutInterceptor;

	public WebConfig(BeforeActionInterceptor beforeActionInterceptor, NeedLoginInterceptor needLoginActionInterceptor,
			NeedLogoutInterceptor needLogoutInterceptor) {
		this.beforeActionInterceptor = beforeActionInterceptor;
		this.needLoginInterceptor = needLoginActionInterceptor;
		this.needLogoutInterceptor = needLogoutInterceptor;
	}

	@Override
	public void addInterceptors(InterceptorRegistry registry) {
		registry.addInterceptor(beforeActionInterceptor).addPathPatterns("/**").excludePathPatterns("/resource/**");

		registry.addInterceptor(needLoginInterceptor).addPathPatterns("/usr/game/startMap")
				.addPathPatterns("/usr/game/happyMap").addPathPatterns("/usr/game/angerMap")
				.addPathPatterns("/usr/game/anxietyMap").addPathPatterns("/usr/game/sadMap")
				.addPathPatterns("/usr/game/zenMap").addPathPatterns("/usr/game/chatBot")
				.addPathPatterns("/usr/member/info").addPathPatterns("/usr/member/customCharacterPage");

		registry.addInterceptor(needLogoutInterceptor).addPathPatterns("/usr/member/signup")
				.addPathPatterns("/usr/member/doSignUp").addPathPatterns("/usr/member/emailSignUp")
				.addPathPatterns("/usr/member/doLogin")
				;

	}

}
