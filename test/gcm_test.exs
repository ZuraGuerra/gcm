defmodule GCMTest do
  use ExUnit.Case
  import :meck
  import GCM

  setup do
    on_exit fn -> unload end
    :ok
  end

  test "push notification to GCM with a 200 response" do
    registration_ids = ["reg1", "reg2"]
    options = %{ data: %{ alert: "Push!" } }
    req_body = "req_body"
    original_resp_body = "original"
    headers = []
    http_response = %HTTPoison.Response{ status_code: 200,
                                         body: original_resp_body,
                                         headers: headers}
    resp_body = %{ "canonical_ids" => 0,
                   "failure" => 0,
                   "success" => 2,
                   "results" => [%{ "error" => "NotRegistered" }] }

    expect(Poison, :encode!, [%{ registration_ids: registration_ids, data: %{ alert: "Push!" } }], req_body)
    expect(Poison, :decode!, 1, resp_body)
    expect(HTTPoison, :post, ["https://android.googleapis.com/gcm/send", req_body, [{"Authorization", "key=api_key"}, {"Content-Type", "application/json"}, {"Accept", "application/json"}]], { :ok, http_response })

    assert push("api_key", registration_ids, options) ==
      { :ok, %{ canonical_ids: [],
                not_registered_ids: [],
                invalid_registration_ids: [],
                success: 2,
                failure: 0,
                status_code: 200,
                body: original_resp_body,
                headers: headers } }

    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with NotRegistered" do
    registration_ids = ["reg1"]
    options = %{ data: %{ alert: "Push!" } }
    req_body = "req_body"
    resp_body = %{ "canonical_ids" => 0,
                   "failure" => 1,
                   "success" => 0,
                   "results" => [%{ "error" => "NotRegistered" }] }
    original_resp_body = "original"
    headers = []

    http_response = %HTTPoison.Response{status_code: 200,
                                        body: original_resp_body,
                                        headers: headers}

    expect(Poison, :encode!, [%{ registration_ids: registration_ids, data: %{ alert: "Push!" } }], req_body)
    expect(Poison, :decode!, [original_resp_body], resp_body)
    expect(HTTPoison, :post, ["https://android.googleapis.com/gcm/send", req_body, [{"Authorization", "key=api_key"}, {"Content-Type", "application/json"}, {"Accept", "application/json"}]], { :ok, http_response })

    assert push("api_key", registration_ids, options) ==
      { :ok, %{ canonical_ids: [],
                not_registered_ids: ["reg1"],
                invalid_registration_ids: [],
                success: 0,
                failure: 1,
                status_code: 200,
                body: original_resp_body,
                headers: headers } }

    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with InvalidRegistration" do
    registration_ids = ["reg1"]
    options = %{ data: %{ alert: "Push!" } }
    req_body = "req_body"
    resp_body = %{ "canonical_ids" => 0,
                   "failure" => 1,
                   "success" => 0,
                   "results" => [%{ "error" => "InvalidRegistration" }] }
    original_resp_body = "original"
    headers = []

    http_response = %HTTPoison.Response{status_code: 200,
                                        body: original_resp_body,
                                        headers: headers}

    expect(Poison, :encode!, [%{ registration_ids: registration_ids, data: %{ alert: "Push!" } }], req_body)
    expect(Poison, :decode!, [original_resp_body], resp_body)
    expect(HTTPoison, :post, ["https://android.googleapis.com/gcm/send", req_body, [{"Authorization", "key=api_key"}, {"Content-Type", "application/json"}, {"Accept", "application/json"}]], { :ok, http_response })

    assert push("api_key", registration_ids, options) ==
      { :ok, %{ canonical_ids: [],
                not_registered_ids: [],
                invalid_registration_ids: ["reg1"],
                success: 0,
                failure: 1,
                status_code: 200,
                body: original_resp_body,
                headers: headers } }

    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with canonical ids" do
    registration_ids = ["reg1"]
    options = %{ data: %{ alert: "Push!" } }
    req_body = "req_body"
    resp_body = %{ "canonical_ids" => 1,
                   "failure" => 0,
                   "success" => 1,
                   "results" => [%{"registration_id" => "newreg1"}] }
    original_resp_body = "original"
    headers = []

    http_response = %HTTPoison.Response{status_code: 200,
                                        body: original_resp_body,
                                        headers: headers}

    expect(Poison, :encode!, [%{ registration_ids: registration_ids, data: %{ alert: "Push!" } }], req_body)
    expect(Poison, :decode!, [original_resp_body], resp_body)
    expect(HTTPoison, :post, ["https://android.googleapis.com/gcm/send", req_body, [{"Authorization", "key=api_key"}, {"Content-Type", "application/json"}, {"Accept", "application/json"}]], { :ok, http_response })

    assert push("api_key", registration_ids, options) ==
      { :ok, %{ canonical_ids: [%{ old: "reg1", new: "newreg1" }],
                not_registered_ids: [],
                invalid_registration_ids: [],
                success: 1,
                failure: 0,
                status_code: 200,
                body: original_resp_body,
                headers: headers } }

    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with a 400 response " do
    registration_ids = ["reg1", "reg2"]
    req_body = "req_body"
    http_response = %HTTPoison.Response{status_code: 400, body: "{}"}

    expect(Poison, :encode!, [%{ registration_ids: registration_ids }], req_body)
    expect(HTTPoison, :post, ["https://android.googleapis.com/gcm/send", req_body, [{"Authorization", "key=api_key"}, {"Content-Type", "application/json"}, {"Accept", "application/json"}]], { :ok, http_response })

    assert push("api_key", registration_ids) == { :error, :bad_request }

    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with a 401 response " do
    registration_ids = ["reg1", "reg2"]
    req_body = "req_body"
    http_response = %HTTPoison.Response{status_code: 401, body: "{}"}

    expect(Poison, :encode!, [%{ registration_ids: registration_ids }], req_body)
    expect(HTTPoison, :post, ["https://android.googleapis.com/gcm/send", req_body, [{"Authorization", "key=api_key"}, {"Content-Type", "application/json"}, {"Accept", "application/json"}]], { :ok, http_response })

    assert push("api_key", registration_ids) == { :error, :unauthorized }

    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with a 503 response " do
    registration_ids = ["reg1", "reg2"]
    req_body = "req_body"
    http_response = %HTTPoison.Response{status_code: 503, body: "{}"}

    expect(Poison, :encode!, [%{ registration_ids: registration_ids }], req_body)
    expect(HTTPoison, :post, ["https://android.googleapis.com/gcm/send", req_body, [{"Authorization", "key=api_key"}, {"Content-Type", "application/json"}, {"Accept", "application/json"}]], { :ok, http_response })

    assert push("api_key", registration_ids) == { :error, :service_unavaiable }

    assert validate [Poison, HTTPoison]
  end

  test "push notification to GCM with a 504 response " do
    registration_ids = ["reg1", "reg2"]
    req_body = "req_body"
    http_response = %HTTPoison.Response{status_code: 504, body: "{}"}

    expect(Poison, :encode!, [%{ registration_ids: registration_ids }], req_body)
    expect(HTTPoison, :post, ["https://android.googleapis.com/gcm/send", req_body, [{"Authorization", "key=api_key"}, {"Content-Type", "application/json"}, {"Accept", "application/json"}]], { :ok, http_response })

    assert push("api_key", registration_ids) == { :error, :server_error }

    assert validate [Poison, HTTPoison]
  end
end
