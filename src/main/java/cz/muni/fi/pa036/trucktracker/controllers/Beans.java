/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package cz.muni.fi.pa036.trucktracker.controllers;

import com.graphhopper.GHResponse;
import com.graphhopper.GraphHopper;
import com.graphhopper.http.RouteSerializer;
import com.graphhopper.http.SimpleRouteSerializer;
import com.graphhopper.util.CmdArgs;
import com.graphhopper.util.PointList;
import java.util.Map;
import javax.inject.Inject;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;


/**
 *
 * @author Petr2
 */
@Configuration
public class Beans {
        
    
    @Bean
    public GraphHopper graphHopper() {
        CmdArgs args = null;
        try{
            args = CmdArgs.readFromConfig("config.properties", "graphhopper.config");       
        }catch(Exception e){
        }
        GraphHopper hopper = new GraphHopper().forServer().init(args);
        hopper.importOrLoad();
        return hopper;
    }
    
    @Bean
    public RouteSerializer routeSerializer() {
        return new SimpleRouteSerializer( graphHopper().getGraphHopperStorage().getBounds() );
    }
    
    @Bean
    public boolean jsonpAllowed(){
        return true;
    }
   
}
