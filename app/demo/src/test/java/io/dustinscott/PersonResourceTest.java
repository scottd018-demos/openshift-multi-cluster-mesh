package io.dustinscott;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
public class PersonResourceTest {

    @Test
    public void testHellov1Endpoint() {
        given()
          .when().get("/api/person/v1")
          .then()
             .statusCode(200)
             .body(is("v1"));
    }

    @Test
    public void testHellov2Endpoint() {
        given()
          .when().get("/api/person/v2")
          .then()
             .statusCode(200)
             .body(is("v2"));
    }
}