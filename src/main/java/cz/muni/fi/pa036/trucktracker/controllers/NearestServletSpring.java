/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package cz.muni.fi.pa036.trucktracker.controllers;

import com.graphhopper.http.NearestServlet;
import javax.servlet.ServletException;
import org.springframework.beans.factory.config.AutowireCapableBeanFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.context.support.AnnotationConfigWebApplicationContext;

/**
 *
 * @author Petr2
 */
@Component
public class NearestServletSpring extends NearestServlet {

    protected AutowireCapableBeanFactory ctx;
    private AnnotationConfigWebApplicationContext context;
    
    public NearestServletSpring () {
    }
    
    public NearestServletSpring (AnnotationConfigWebApplicationContext context) {
        this.context = context;
    }
    

    @Override
    public void init() throws ServletException {
        super.init();
        ctx = context.getAutowireCapableBeanFactory();
        //The following line does the magic
        ctx.autowireBean(this);
    }

}
