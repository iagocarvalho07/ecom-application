package com.ap.ecom.service;

import com.ap.ecom.dto.UserRequest;
import com.ap.ecom.dto.UserResponse;

import java.util.List;
import java.util.Optional;

public interface UserService {
    public List<UserResponse> fetchAllUsers();
    public void addUser(UserRequest userRequest);
    public Optional<UserResponse> fetchUser(String id);
    public boolean updateUser(String id, UserRequest updatedUserRequest);

}
