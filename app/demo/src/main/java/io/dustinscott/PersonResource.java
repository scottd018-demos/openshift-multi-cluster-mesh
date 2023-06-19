package io.dustinscott;

import java.util.List;
import io.quarkus.panache.common.Sort;

import org.jboss.logging.Logger;

import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

@Path("/person")
@ApplicationScoped
@Produces("application/json")
@Consumes("application/json")
public class PersonResource {

    private static final Logger LOGGER = Logger.getLogger(PersonResource.class.getName());

    @GET
    public List<Person> get() {
        return Person.listAll(Sort.by("firstName"));
    }

    @GET
    @Path("{id}")
    public Person getSingle(Long id) {
        Person entity = Person.findById(id);
        if (entity == null) {
            throw new WebApplicationException("Person with id of " + id + " does not exist.", 404);
        }

        return entity;
    }

    @POST
    @Transactional
    public Response create(Person person) {
        if (person.id != null) {
            throw new WebApplicationException("Id was invalidly set on request.", 422);
        }

        person.persist();

        return Response.ok(person).status(201).build();
    }

    @PUT
    @Path("{id}")
    @Transactional
    public Person update(Long id, Person person) {
        Person entity = Person.findById(id);

        if (entity == null) {
            throw new WebApplicationException("Person with id of " + id + " does not exist.", 404);
        }

        if (person.firstName != null) {
            entity.firstName = person.firstName;
        }

        if (person.lastName != null) {
            entity.lastName = person.lastName;
        }

        return entity;
    }

    @DELETE
    @Path("{id}")
    @Transactional
    public Response delete(Long id) {
        Person entity = Person.findById(id);
        if (entity == null) {
            throw new WebApplicationException("Person with id of " + id + " does not exist.", 404);
        }
        entity.delete();

        return Response.status(204).build();
    }

    @Provider
    public static class ErrorMapper implements ExceptionMapper<Exception> {

        @Inject
        ObjectMapper objectMapper;

        @Override
        public Response toResponse(Exception exception) {
            LOGGER.error("Failed to handle request", exception);

            int code = 500;
            if (exception instanceof WebApplicationException) {
                code = ((WebApplicationException) exception).getResponse().getStatus();
            }

            ObjectNode exceptionJson = objectMapper.createObjectNode();
            exceptionJson.put("exceptionType", exception.getClass().getName());
            exceptionJson.put("code", code);

            if (exception.getMessage() != null) {
                exceptionJson.put("error", exception.getMessage());
            }

            return Response.status(code)
                    .entity(exceptionJson)
                    .build();
        }

    }
}
