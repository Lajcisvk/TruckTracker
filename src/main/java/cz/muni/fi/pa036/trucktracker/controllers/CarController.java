package cz.muni.fi.pa036.trucktracker.controllers;


import org.json.JSONArray;
import org.json.JSONObject;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.sql.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Controller for project API
 * @author Jan Mosat
 */
@RestController
@RequestMapping("/api")
public class CarController {

    Connection connection = null;
    SimpleDateFormat format = new SimpleDateFormat ("yyyy-MM-dd HH:mm:ss");

    public CarController(){
        try {
            connection = DriverManager.getConnection(System.getenv("JDBC_DATABASE_URL"));
        } catch (SQLException e) {
            System.err.println("Connection Failed! Check output console");
            e.printStackTrace();
        }
    }

    @RequestMapping(method = RequestMethod.GET, produces = MediaType.APPLICATION_JSON_VALUE)
    public final String getCars(@RequestParam(required=false) final String since,
                                @RequestParam(required=false) final String until,
                                @RequestParam(required=false) final String in)
            throws Exception {
        PreparedStatement statement;
        if (in != null)
        {
            statement = connection.prepareStatement(
                    "SELECT DISTINCT on (car_key) * FROM tracking " +
                            "WHERE  time <= ? " +
                            "ORDER  BY car_key, time DESC"
            );
            Date date = parseDate(in);
            statement.setTimestamp(1, new Timestamp(date.getTime()));
        }
        else if ((since == null) && (until == null))
        {
            statement = connection.prepareStatement(
                    "select distinct on (x.car_key) *" +
                            "from (" +
                            "       select car_key, min(time) as mintime " +
                            "       from tracking group by car_key" +
                            "     ) as x inner join tracking as f on f.car_key = x.car_key and f.time = x.mintime " +
                            "union all " +
                            "select distinct on (x.car_key) *" +
                            "from (" +
                            "       select car_key, max(time) as maxtime" +
                            "       from tracking group by car_key" +
                            "     ) as x inner join tracking as f on f.car_key = x.car_key and f.time=x.maxtime order by 1, time;"
            );
        }
        else {
            Date sinceDate = (since == null) ? new Date(0) : parseDate(since);
            Date untilDate = (until == null) ? new Date() : parseDate(until);

            statement = connection.prepareStatement("SELECT * FROM tracking WHERE time BETWEEN ? and ?");
            statement.setTimestamp(1, new Timestamp(sinceDate.getTime()));
            statement.setTimestamp(2, new Timestamp(untilDate.getTime()));
        }
        ResultSet resultSet = statement.executeQuery();

        return makeJSON(resultSet);
    }

    @ResponseStatus(value= HttpStatus.BAD_REQUEST, reason="Request was in incorrect format")
    @ExceptionHandler(Exception.class)
    public void Error() {
    }

    private String makeJSON(ResultSet resultSet) throws SQLException {
        PreparedStatement statement = connection.prepareStatement(
                "SELECT car_key, spz, make, color, production_year, type, eco_speed FROM car"
        );
        ResultSet carsResultSet = statement.executeQuery();
        JSONArray carsJson = convertResultSetIntoJSON(carsResultSet);

        JSONArray pureJson = convertResultSetIntoJSON(resultSet);
        JSONArray groupedJson = new JSONArray();
        int i = - 1;
        for (Object b : pureJson) {
            JSONObject jsonObject = (JSONObject) b;
            Long car_key = (Long) jsonObject.get("car_key");
            if (groupedJson.length() == 0 || !((JSONObject) groupedJson.get(i)).get("car_key").equals(car_key) ){
                i++;
                JSONObject car = getCarWithKey(carsJson, car_key);
                car.put("data", new JSONArray());
                groupedJson.put(i, car);
            }
            jsonObject.remove("car_key");
            ((JSONObject) groupedJson.get(i)).append("data", jsonObject);
        }
        return groupedJson.toString();
    }

    private static JSONArray convertResultSetIntoJSON(ResultSet resultSet) throws SQLException {
        JSONArray jsonArray = new JSONArray();
        while (resultSet.next()) {
            int total_rows = resultSet.getMetaData().getColumnCount();
            JSONObject obj = new JSONObject();
            for (int i = 0; i < total_rows; i++) {
                String columnName = resultSet.getMetaData().getColumnLabel(i + 1).toLowerCase();
                Object columnValue = resultSet.getObject(i + 1);
                // if value in DB is null, then we set it to default value
                if (columnValue == null){
                    columnValue = "null";
                }
                /*
                Next if block is a hack. In case when in db we have values like price and price1 there's a bug in jdbc -
                both this names are getting stored as price in ResulSet. Therefore when we store second column value,
                we overwrite original value of price. To avoid that, i simply add 1 to be consistent with DB.
                 */
                if (obj.has(columnName)){
                    columnName += "1";
                }
                obj.put(columnName, columnValue);
            }
            jsonArray.put(obj);
        }
        return jsonArray;
    }

    private static JSONObject getCarWithKey(JSONArray carsJson, Long key){
        for (Object jsonObject : carsJson) {
            JSONObject json = (JSONObject) jsonObject;
            if (json.get("car_key").equals(key))
                return json;
        }
        return null;
    }

    private Date parseDate(String date) throws ParseException {
        return format.parse(date);
    }
}