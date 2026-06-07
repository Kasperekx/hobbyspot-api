defmodule HobbyspotBackendWeb.OpenApiSpec do
  @moduledoc """
  OpenAPI specification for the mobile-facing HTTP API.
  """

  @version "0.1.0"

  def spec do
    %{
      "openapi" => "3.0.3",
      "info" => %{
        "title" => "Hobbyspot API",
        "version" => @version,
        "description" =>
          "Backend API for the Hobbyspot mobile application and future admin panel."
      },
      "servers" => [
        %{
          "url" => "http://localhost:4000",
          "description" => "Local development"
        }
      ],
      "tags" => [
        %{"name" => "Auth", "description" => "Registration, login and current user session"},
        %{"name" => "Onboarding", "description" => "User profile and onboarding data"},
        %{"name" => "Location", "description" => "Planned user location endpoint contract"}
      ],
      "paths" => paths(),
      "components" => components()
    }
  end

  defp paths do
    %{
      "/api/users/register" => %{
        "post" => %{
          "tags" => ["Auth"],
          "summary" => "Register a user",
          "requestBody" => json_request("RegisterRequest"),
          "responses" => %{
            "201" => json_response("AuthResponse", "User registered"),
            "422" => json_response("ValidationError", "Validation failed")
          }
        }
      },
      "/api/users/log-in" => %{
        "post" => %{
          "tags" => ["Auth"],
          "summary" => "Log in with email and password",
          "requestBody" => json_request("LoginRequest"),
          "responses" => %{
            "200" => json_response("AuthResponse", "Logged in"),
            "401" => json_response("ErrorResponse", "Invalid credentials")
          }
        }
      },
      "/api/users/me" => %{
        "get" => %{
          "tags" => ["Auth"],
          "summary" => "Return the authenticated user",
          "security" => bearer_security(),
          "responses" => %{
            "200" => json_response("CurrentUserResponse", "Current user"),
            "401" => json_response("ErrorResponse", "Unauthorized")
          }
        }
      },
      "/api/users/me/onboarding" => %{
        "patch" => %{
          "tags" => ["Onboarding"],
          "summary" => "Update onboarding profile fields",
          "description" =>
            "Updates profile fields collected during onboarding and marks onboarding_completed as true.",
          "security" => bearer_security(),
          "requestBody" => json_request("OnboardingRequest"),
          "responses" => %{
            "200" => json_response("CurrentUserResponse", "Updated user"),
            "401" => json_response("ErrorResponse", "Unauthorized"),
            "422" => json_response("ValidationError", "Validation failed")
          }
        }
      },
      "/api/users/me/location" => %{
        "put" => %{
          "tags" => ["Location"],
          "summary" => "Upsert onboarding location",
          "description" =>
            "Planned endpoint contract for the onboarding location step. The database schema already supports storing one location per user.",
          "security" => bearer_security(),
          "requestBody" => json_request("LocationRequest"),
          "responses" => %{
            "200" => json_response("LocationResponse", "Location updated"),
            "401" => json_response("ErrorResponse", "Unauthorized"),
            "422" => json_response("ValidationError", "Validation failed")
          },
          "x-status" => "planned"
        }
      },
      "/api/users/log-out" => %{
        "delete" => %{
          "tags" => ["Auth"],
          "summary" => "Log out the current bearer token",
          "security" => bearer_security(),
          "responses" => %{
            "204" => %{"description" => "Token deleted"},
            "401" => json_response("ErrorResponse", "Unauthorized")
          }
        }
      }
    }
  end

  defp components do
    %{
      "securitySchemes" => %{
        "bearerAuth" => %{
          "type" => "http",
          "scheme" => "bearer",
          "bearerFormat" => "Opaque"
        }
      },
      "schemas" => %{
        "RegisterRequest" => %{
          "type" => "object",
          "required" => ["user"],
          "properties" => %{
            "user" => %{
              "type" => "object",
              "required" => ["email", "password"],
              "properties" => %{
                "email" => %{"type" => "string", "format" => "email"},
                "password" => %{"type" => "string", "format" => "password", "minLength" => 12}
              }
            }
          }
        },
        "LoginRequest" => %{
          "type" => "object",
          "required" => ["user"],
          "properties" => %{
            "user" => %{
              "type" => "object",
              "required" => ["email", "password"],
              "properties" => %{
                "email" => %{"type" => "string", "format" => "email"},
                "password" => %{"type" => "string", "format" => "password"}
              }
            }
          }
        },
        "OnboardingRequest" => %{
          "type" => "object",
          "required" => ["user"],
          "properties" => %{
            "user" => %{
              "type" => "object",
              "properties" => %{
                "avatar_url" => nullable_string("uri"),
                "full_name" => nullable_string(),
                "birth_date" => %{
                  "type" => "string",
                  "format" => "date",
                  "nullable" => true,
                  "example" => "1994-04-12"
                }
              }
            }
          }
        },
        "LocationRequest" => %{
          "type" => "object",
          "required" => ["location"],
          "properties" => %{
            "location" => %{
              "type" => "object",
              "required" => ["latitude", "longitude"],
              "properties" => %{
                "latitude" => %{"type" => "number", "minimum" => -90, "maximum" => 90},
                "longitude" => %{"type" => "number", "minimum" => -180, "maximum" => 180},
                "city" => nullable_string(),
                "country_code" => nullable_string(),
                "label" => nullable_string(),
                "search_radius_meters" => %{
                  "type" => "integer",
                  "minimum" => 100,
                  "maximum" => 100_000,
                  "default" => 5000
                },
                "source" => %{
                  "type" => "string",
                  "enum" => ["manual", "gps"],
                  "default" => "manual"
                }
              }
            }
          }
        },
        "AuthResponse" => %{
          "type" => "object",
          "properties" => %{
            "data" => %{
              "type" => "object",
              "properties" => %{
                "token" => %{"type" => "string"},
                "user" => schema_ref("User")
              }
            }
          }
        },
        "CurrentUserResponse" => %{
          "type" => "object",
          "properties" => %{
            "data" => %{
              "type" => "object",
              "properties" => %{
                "user" => schema_ref("User")
              }
            }
          }
        },
        "LocationResponse" => %{
          "type" => "object",
          "properties" => %{
            "data" => %{
              "type" => "object",
              "properties" => %{
                "location" => schema_ref("Location")
              }
            }
          }
        },
        "User" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string", "format" => "uuid"},
            "email" => %{"type" => "string", "format" => "email"},
            "avatar_url" => nullable_string("uri"),
            "full_name" => nullable_string(),
            "birth_date" => %{"type" => "string", "format" => "date", "nullable" => true},
            "confirmed_at" => %{"type" => "string", "format" => "date-time", "nullable" => true},
            "onboarding_completed" => %{"type" => "boolean"}
          }
        },
        "Location" => %{
          "type" => "object",
          "properties" => %{
            "id" => %{"type" => "string", "format" => "uuid"},
            "latitude" => %{"type" => "number"},
            "longitude" => %{"type" => "number"},
            "city" => nullable_string(),
            "country_code" => nullable_string(),
            "label" => nullable_string(),
            "search_radius_meters" => %{"type" => "integer"},
            "source" => %{"type" => "string"}
          }
        },
        "ErrorResponse" => %{
          "type" => "object",
          "properties" => %{
            "errors" => %{
              "type" => "object",
              "properties" => %{
                "detail" => %{"type" => "string"}
              }
            }
          }
        },
        "ValidationError" => %{
          "type" => "object",
          "properties" => %{
            "errors" => %{
              "type" => "object",
              "additionalProperties" => %{
                "type" => "array",
                "items" => %{"type" => "string"}
              }
            }
          }
        }
      }
    }
  end

  defp bearer_security, do: [%{"bearerAuth" => []}]

  defp json_request(schema) do
    %{
      "required" => true,
      "content" => %{
        "application/json" => %{
          "schema" => schema_ref(schema)
        }
      }
    }
  end

  defp json_response(schema, description) do
    %{
      "description" => description,
      "content" => %{
        "application/json" => %{
          "schema" => schema_ref(schema)
        }
      }
    }
  end

  defp schema_ref(name), do: %{"$ref" => "#/components/schemas/#{name}"}

  defp nullable_string(format \\ nil) do
    schema = %{"type" => "string", "nullable" => true}

    if format do
      Map.put(schema, "format", format)
    else
      schema
    end
  end
end
