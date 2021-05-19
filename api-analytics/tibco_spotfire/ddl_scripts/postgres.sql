/*
* Copyright © 2021. TIBCO Software Inc.
* This file is subject to the license terms contained
* in the license file that is distributed with this file.
*/

CREATE DATABASE masherylocallogs;

\c masherylocallogs;

DROP TABLE IF EXISTS tmlaccesslog;
CREATE TABLE tmlaccesslog (
    api_key varchar(255),
    api_method varchar(255),
    bytes numeric(11),
    cache_hit numeric(1),
    client_transfer_time float,
    connect_time float,
    endpoint_name varchar(255),
    method varchar(255),
    status numeric(11),
    http_version varchar(255),
    oauth_access_token varchar(255),
    package_name varchar(255),
    package_uuid varchar(255),
    plan_name varchar(255),
    plan_uuid varchar(255),
    pre_transfer_time float,
    throttle_value numeric(11),
    quota_value numeric(11),
    referrer varchar(255),
    remote_total_time float,
    request_host_name varchar(255),
    request_id varchar(255) NOT NULL,
    request_time timestamp,
    request_uuid varchar(255),
    response_string varchar(255),
    epkey varchar(255),
    spkey varchar(255),
    service_name varchar(255),
    src_ip varchar(255),
    ssl_enabled numeric(1),
    exec_time float4,
    proxy varchar(255),
    proxy_error_code varchar(255),
    uri varchar(4096),
    user_agent varchar(255),
    org_name varchar(255),
    org_uuid char (36),
    sub_org_name varchar(255),
    sub_org_uuid char(36),
    PRIMARY KEY (request_uuid)
);
