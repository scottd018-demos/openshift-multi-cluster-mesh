package io.dustinscott;

import jakarta.persistence.Entity;
import jakarta.persistence.Column;
import jakarta.persistence.Cacheable;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

@Entity
@Cacheable
public class Person extends PanacheEntity {
    @Column(name="first_name") 
    public String firstName;

	@Column(name="last_name") 
    public String lastName;

    public Person() {
    }

    public Person(String firstName, String lastName) {
        this.firstName = firstName;
        this.lastName = lastName;
    }
}
