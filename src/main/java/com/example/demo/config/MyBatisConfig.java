package com.example.demo.config;

import com.example.demo.handler.JsonNodeTypeHandler;
import com.fasterxml.jackson.databind.JsonNode;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import javax.sql.DataSource;

@Configuration
public class MyBatisConfig {
    
    @Bean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        SqlSessionFactoryBean sessionFactory = new SqlSessionFactoryBean();
        sessionFactory.setDataSource(dataSource);
        
        org.apache.ibatis.session.Configuration configuration = new org.apache.ibatis.session.Configuration();
        configuration.getTypeHandlerRegistry().register(JsonNode.class, JsonNodeTypeHandler.class);
        configuration.setMapUnderscoreToCamelCase(true);
        
        sessionFactory.setConfiguration(configuration);
        return sessionFactory.getObject();
    }
}