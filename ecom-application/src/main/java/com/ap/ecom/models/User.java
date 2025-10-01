package com.ap.ecom.models;

import jakarta.persistence.*;
import lombok.Data;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;

import java.time.LocalDateTime;

@Data
@Entity(name = "user_table")
public class User {
   @Id
   @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(length = 100)
    private String keycloakId;
    @Column(length = 100)
    private String firstName;
    @Column(length = 100)
    private String lastName;
//@Indexed(unique = true)
    @Column(length = 100)
    private String email;
    @Column(length = 20)
    private String phone;
    @Enumerated(EnumType.STRING)
    private UserRole role = UserRole.CUSTOMER;
    @OneToOne(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "address_id", referencedColumnName = "id")
    private Address address;
   @CreatedDate
    private LocalDateTime createdAt;
   @LastModifiedDate
    private LocalDateTime updatedAt;
}
