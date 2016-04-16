package cz.muni.fi.pa036.trucktracker.controllers;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.io.StringWriter;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Rest Controller for book
 * @author Jan Mosat
 */
@RestController
@RequestMapping("/api/car")
public class BookController {

    Connection connection = null;

    public BookController(){
        try {
            connection = DriverManager.getConnection(System.getenv("JDBC_DATABASE_URL"));

        } catch (SQLException e) {
            System.out.println("Connection Failed! Check output console");
            e.printStackTrace();
        }
    }

    @RequestMapping(method = RequestMethod.GET, produces = MediaType.APPLICATION_JSON_VALUE)
    public final String getBooks() throws SQLException, IOException {
        PreparedStatement st = connection.prepareStatement("select * from car");
        ResultSet r1=st.executeQuery();
        List<JSONObject> car = new ArrayList<>();

        while (r1.next()) {
            JSONObject obj = new JSONObject();
            obj.put("make", r1.getString("make"));
            obj.put("spz", r1.getString("spz"));
            obj.put("type", r1.getString("type"));
            obj.put("tonnage", r1.getString("tonnage"));
            car.add(obj);
        }
        JSONArray cars = new JSONArray();
        cars.addAll(car);
        StringWriter out = new StringWriter();
        cars.writeJSONString(out);
        return out.toString();
    }
}