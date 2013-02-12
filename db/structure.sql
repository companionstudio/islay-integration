--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


SET search_path = public, pg_catalog;

--
-- Name: formatted_money(double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION formatted_money(double precision, OUT text) RETURNS text
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN $1 IS NULL OR $1 = 0 THEN '$0.00'
            ELSE '$' || TRIM(TO_CHAR($1, '999999999999D99'))
          END
      $_$;


--
-- Name: formatted_volume(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION formatted_volume(numeric, OUT text) RETURNS text
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN $1 IS NULL THEN NULL
            WHEN $1 >= 1000 THEN ($1::float / 1000)::text || 'l'
            ELSE $1::text || 'ml'
          END
      $_$;


--
-- Name: formatted_weight(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION formatted_weight(numeric, OUT text) RETURNS text
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN $1 IS NULL THEN NULL
            WHEN $1 >= 1000 THEN ($1::float / 1000)::text || 'kg'
            ELSE $1::text || 'g'
          END
      $_$;


--
-- Name: is_revenue(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_revenue(text, OUT boolean) RETURNS boolean
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN $1 NOT IN ('pending', 'cancelled') THEN true
            ELSE false
          END
      $_$;


--
-- Name: movement_dir(numeric, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION movement_dir(numeric, numeric, OUT text) RETURNS text
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN $1 = $2 THEN 'none'
            WHEN $1 > $2 THEN 'up'
            WHEN $1 < $2 THEN 'down'
            ELSE 'na'
          END
      $_$;


--
-- Name: movement_dir(double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION movement_dir(double precision, double precision, OUT text) RETURNS text
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN $1 = $2 THEN 'none'
            WHEN $1 > $2 THEN 'up'
            WHEN $1 < $2 THEN 'down'
            ELSE 'na'
          END
      $_$;


--
-- Name: update_status(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_status(timestamp without time zone, timestamp without time zone, OUT text) RETURNS text
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN ($2 - $1) < '5 minute'::interval THEN 'created'
            ELSE 'updated'
          END
      $_$;


--
-- Name: within_dates(text, text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION within_dates(text, text, timestamp without time zone, OUT boolean) RETURNS boolean
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN DATE_TRUNC('day', $3) >= $1 ::timestamp
            AND DATE_TRUNC('day', $3) <= $2 ::timestamp THEN true
            ELSE false
          END
      $_$;


--
-- Name: within_last(text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION within_last(text, timestamp without time zone, OUT boolean) RETURNS boolean
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN DATE_TRUNC($1, $2) = DATE_TRUNC($1, NOW() - ('1 ' || $1)::interval) THEN true
            ELSE false
          END
      $_$;


--
-- Name: within_month(numeric, numeric, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION within_month(numeric, numeric, timestamp without time zone, OUT boolean) RETURNS boolean
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN DATE_PART('year', $3) = $1 AND DATE_PART('month', $3) = $2 THEN true
            ELSE false
          END
      $_$;


--
-- Name: within_previous_dates(text, text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION within_previous_dates(text, text, timestamp without time zone, OUT boolean) RETURNS boolean
    LANGUAGE sql
    AS $_$
        WITH times AS (
          SELECT
            $1::timestamp AS start_time,
            ($2 || ' 23:59:59')::timestamp AS end_time
        )

        SELECT
          $3 >= (start_time - span) AND $3 <= (end_time - span)
        FROM (
          SELECT
            (SELECT start_time FROM times) AS start_time,
            (SELECT end_time FROM times) AS end_time,
            (SELECT end_time FROM times) - (SELECT start_time FROM times) AS span
        ) AS vals
      $_$;


--
-- Name: within_previous_month(numeric, numeric, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION within_previous_month(numeric, numeric, timestamp without time zone, OUT boolean) RETURNS boolean
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN current_month = true AND last_day = false THEN
              (SELECT $3 >= previous_start AND $3 <= (NOW() - '1 month'::interval))
            ELSE
              (SELECT $3 >= previous_start AND $3 <= previous_end)
          END
        FROM (
          SELECT
            TO_TIMESTAMP($1::text || $2::text, 'YYYYMM') - '1 month'::interval AS previous_start,
            TO_TIMESTAMP($1::text || $2::text, 'YYYYMM') - '1 second'::interval AS previous_end,
            (DATE_PART('month', CURRENT_DATE) = $2) AS current_month,
            (DATE_PART('day',(DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 MONTH - 1 day')) = DATE_PART('day', CURRENT_DATE)) AS last_day
        ) AS tests
      $_$;


--
-- Name: within_this(text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION within_this(text, timestamp without time zone, OUT boolean) RETURNS boolean
    LANGUAGE sql
    AS $_$
        SELECT
          CASE
            WHEN DATE_TRUNC($1, $2) = DATE_TRUNC($1, NOW()) THEN true
            ELSE false
          END
      $_$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: applied_promotions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE applied_promotions (
    id integer NOT NULL,
    promotion_id integer NOT NULL,
    promotion_effect_id integer NOT NULL,
    order_id integer NOT NULL,
    qualifying_order_item_id integer,
    bonus_order_item_id integer,
    created_at timestamp without time zone
);


--
-- Name: applied_promotions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE applied_promotions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applied_promotions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE applied_promotions_id_seq OWNED BY applied_promotions.id;


--
-- Name: asset_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE asset_groups (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    assets_count integer DEFAULT 0 NOT NULL,
    creator_id integer NOT NULL,
    updater_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms tsvector,
    path ltree
);


--
-- Name: asset_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE asset_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE asset_groups_id_seq OWNED BY asset_groups.id;


--
-- Name: asset_taggings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE asset_taggings (
    id integer NOT NULL,
    asset_id integer NOT NULL,
    asset_tag_id integer NOT NULL
);


--
-- Name: asset_taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE asset_taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE asset_taggings_id_seq OWNED BY asset_taggings.id;


--
-- Name: asset_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE asset_tags (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(200) NOT NULL
);


--
-- Name: asset_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE asset_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE asset_tags_id_seq OWNED BY asset_tags.id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assets (
    id integer NOT NULL,
    asset_group_id integer NOT NULL,
    type character varying(50) NOT NULL,
    name character varying(200) NOT NULL,
    key character varying(200) NOT NULL,
    dir character varying(6) NOT NULL,
    filename character varying(200) NOT NULL,
    original_filename character varying(200) NOT NULL,
    filesize integer,
    content_type character varying(100),
    colorspace character varying(20),
    width integer,
    height integer,
    under_size boolean DEFAULT false NOT NULL,
    video_codec character varying(50),
    video_bitrate integer,
    video_frame_rate real,
    audio_codec character varying(50),
    audio_bitrate integer,
    audio_sample_rate integer,
    audio_channels smallint,
    duration real,
    status character varying(20) DEFAULT 'enqueued'::character varying NOT NULL,
    error character varying(255),
    retries smallint DEFAULT 0 NOT NULL,
    creator_id integer NOT NULL,
    updater_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms tsvector
);


--
-- Name: assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assets_id_seq OWNED BY assets.id;


--
-- Name: blog_assets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE blog_assets (
    id integer NOT NULL,
    blog_entry_id integer NOT NULL,
    asset_id integer NOT NULL,
    "position" integer DEFAULT 1 NOT NULL
);


--
-- Name: blog_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE blog_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blog_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE blog_assets_id_seq OWNED BY blog_assets.id;


--
-- Name: blog_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE blog_comments (
    id integer NOT NULL,
    blog_entry_id integer NOT NULL,
    name character varying(200) NOT NULL,
    email character varying(200) NOT NULL,
    body character varying(2000) NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms tsvector
);


--
-- Name: blog_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE blog_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blog_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE blog_comments_id_seq OWNED BY blog_comments.id;


--
-- Name: blog_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE blog_entries (
    id integer NOT NULL,
    author_id integer NOT NULL,
    title character varying(200) NOT NULL,
    slug character varying(200) NOT NULL,
    body character varying(8000) NOT NULL,
    metadata hstore,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp without time zone,
    first_published_at timestamp without time zone,
    creator_id integer NOT NULL,
    updater_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms tsvector
);


--
-- Name: blog_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE blog_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blog_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE blog_entries_id_seq OWNED BY blog_entries.id;


--
-- Name: blog_taggings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE blog_taggings (
    id integer NOT NULL,
    blog_entry_id integer NOT NULL,
    blog_tag_id integer NOT NULL
);


--
-- Name: blog_taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE blog_taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blog_taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE blog_taggings_id_seq OWNED BY blog_taggings.id;


--
-- Name: blog_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE blog_tags (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(200) NOT NULL
);


--
-- Name: blog_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE blog_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blog_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE blog_tags_id_seq OWNED BY blog_tags.id;


--
-- Name: credit_card_payments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE credit_card_payments (
    id integer NOT NULL,
    order_id integer NOT NULL,
    successful boolean DEFAULT false NOT NULL,
    amount double precision NOT NULL,
    first_name character varying(200) NOT NULL,
    last_name character varying(200) NOT NULL,
    number character varying(25) NOT NULL,
    month bigint NOT NULL,
    year bigint NOT NULL,
    gateway_id character varying(60) NOT NULL,
    gateway_expiry timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    card_type character varying(30) DEFAULT NULL::character varying NOT NULL
);


--
-- Name: credit_card_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE credit_card_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: credit_card_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE credit_card_payments_id_seq OWNED BY credit_card_payments.id;


--
-- Name: credit_card_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE credit_card_transactions (
    id integer NOT NULL,
    credit_card_payment_id integer NOT NULL,
    transaction_id character varying(60) NOT NULL,
    transaction_type character varying(50) NOT NULL,
    amount double precision NOT NULL,
    currency character varying(4) DEFAULT 'AUD'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: credit_card_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE credit_card_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: credit_card_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE credit_card_transactions_id_seq OWNED BY credit_card_transactions.id;


--
-- Name: features; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE features (
    id integer NOT NULL,
    page_id integer NOT NULL,
    primary_asset_id integer,
    secondary_asset_id integer,
    "position" integer DEFAULT 1 NOT NULL,
    title character varying(255) NOT NULL,
    description character varying(255),
    styles character varying(255),
    published boolean DEFAULT false NOT NULL,
    published_at timestamp without time zone,
    first_published_at timestamp without time zone,
    creator_id integer NOT NULL,
    updater_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    link_url character varying(255),
    link_title character varying(255)
);


--
-- Name: features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE features_id_seq OWNED BY features.id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE order_items (
    id integer NOT NULL,
    order_id integer NOT NULL,
    sku_id integer NOT NULL,
    quantity integer NOT NULL,
    type character varying(50) DEFAULT 'regular'::character varying NOT NULL,
    batch_size bigint,
    batch_price double precision,
    original_price double precision NOT NULL,
    original_total double precision NOT NULL,
    discount double precision DEFAULT 0 NOT NULL,
    adjusted_price double precision NOT NULL,
    total double precision NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE order_items_id_seq OWNED BY order_items.id;


--
-- Name: order_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE order_logs (
    id integer NOT NULL,
    order_id integer NOT NULL,
    succeeded boolean DEFAULT true NOT NULL,
    action character varying(20) NOT NULL,
    notes character varying(2000),
    creator_id integer,
    updater_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: order_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE order_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE order_logs_id_seq OWNED BY order_logs.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE orders (
    id integer NOT NULL,
    person_id integer,
    status character varying(50) DEFAULT 'open'::character varying NOT NULL,
    reference character varying(11) NOT NULL,
    name character varying(200) NOT NULL,
    phone character varying(50),
    email character varying(200) NOT NULL,
    is_gift boolean DEFAULT false,
    shipping_name character varying(200),
    gift_message character varying(4000),
    billing_street character varying(200) NOT NULL,
    billing_city character varying(200) NOT NULL,
    billing_state character varying(200) NOT NULL,
    billing_postcode character varying(25) NOT NULL,
    billing_country character varying(2) NOT NULL,
    shipping_street character varying(200),
    shipping_city character varying(200),
    shipping_state character varying(200),
    shipping_postcode character varying(25),
    shipping_country character varying(2),
    shipping_instructions character varying(4000),
    use_shipping_address boolean DEFAULT false NOT NULL,
    original_product_total double precision NOT NULL,
    product_total double precision NOT NULL,
    original_shipping_total double precision NOT NULL,
    shipping_total double precision NOT NULL,
    original_total double precision NOT NULL,
    total double precision NOT NULL,
    discount double precision DEFAULT 0 NOT NULL,
    currency character varying(4) DEFAULT 'AUD'::character varying NOT NULL,
    creator_id integer,
    updater_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms tsvector,
    tracking_reference character varying(30),
    billing_company character varying(200),
    shipping_company character varying(200)
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE orders_id_seq OWNED BY orders.id;


--
-- Name: page_assets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE page_assets (
    id integer NOT NULL,
    page_id integer NOT NULL,
    asset_id integer NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: page_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE page_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE page_assets_id_seq OWNED BY page_assets.id;


--
-- Name: pages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pages (
    id integer NOT NULL,
    slug character varying(50) NOT NULL,
    entries hstore,
    creator_id integer NOT NULL,
    updater_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pages_id_seq OWNED BY pages.id;


--
-- Name: people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE people (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    email character varying(200) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE people_id_seq OWNED BY people.id;


--
-- Name: product_assets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE product_assets (
    id integer NOT NULL,
    product_id integer NOT NULL,
    asset_id integer NOT NULL,
    "position" integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: product_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_assets_id_seq OWNED BY product_assets.id;


--
-- Name: product_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE product_categories (
    id integer NOT NULL,
    asset_id integer,
    "position" integer DEFAULT 1 NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    description character varying(4000) NOT NULL,
    status character varying(20) DEFAULT 'for_sale'::character varying NOT NULL,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp without time zone,
    first_published_at timestamp without time zone,
    creator_id integer NOT NULL,
    updater_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms tsvector,
    path ltree
);


--
-- Name: product_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_categories_id_seq OWNED BY product_categories.id;


--
-- Name: product_ranges; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE product_ranges (
    id integer NOT NULL,
    asset_id integer,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    description character varying(4000) NOT NULL,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp without time zone,
    first_published_at timestamp without time zone,
    creator_id integer NOT NULL,
    updater_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms tsvector
);


--
-- Name: product_ranges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_ranges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_ranges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_ranges_id_seq OWNED BY product_ranges.id;


--
-- Name: product_variant_assets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE product_variant_assets (
    id integer NOT NULL,
    product_variant_id integer NOT NULL,
    asset_id integer NOT NULL,
    "position" integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: product_variant_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_variant_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_variant_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_variant_assets_id_seq OWNED BY product_variant_assets.id;


--
-- Name: product_variants; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE product_variants (
    id integer NOT NULL,
    product_id integer NOT NULL,
    "position" integer DEFAULT 1 NOT NULL,
    name character varying(200) NOT NULL,
    description character varying(4000) NOT NULL,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp without time zone,
    status character varying(20) DEFAULT 'for_sale'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: product_variants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE product_variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_variants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE product_variants_id_seq OWNED BY product_variants.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE products (
    id integer NOT NULL,
    product_category_id integer NOT NULL,
    product_range_id integer,
    "position" integer DEFAULT 1 NOT NULL,
    type character varying(50) DEFAULT 'Product'::character varying NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(200) NOT NULL,
    description character varying(4000),
    metadata hstore,
    status character varying(20) DEFAULT 'for_sale'::character varying NOT NULL,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp without time zone,
    first_published_at timestamp without time zone,
    creator_id integer NOT NULL,
    updater_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms tsvector
);


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE products_id_seq OWNED BY products.id;


--
-- Name: promotion_conditions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE promotion_conditions (
    id integer NOT NULL,
    promotion_id integer NOT NULL,
    type character varying(50) NOT NULL,
    config hstore,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: promotion_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE promotion_conditions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE promotion_conditions_id_seq OWNED BY promotion_conditions.id;


--
-- Name: promotion_effects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE promotion_effects (
    id integer NOT NULL,
    promotion_id integer NOT NULL,
    type character varying(50) NOT NULL,
    config hstore,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: promotion_effects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE promotion_effects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotion_effects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE promotion_effects_id_seq OWNED BY promotion_effects.id;


--
-- Name: promotions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE promotions (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    description character varying(4000),
    active boolean DEFAULT false NOT NULL,
    start_at timestamp without time zone NOT NULL,
    end_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms tsvector,
    application_limit integer,
    slug character varying(200)
);


--
-- Name: promotions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE promotions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE promotions_id_seq OWNED BY promotions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sku_assets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sku_assets (
    id integer NOT NULL,
    sku_id integer NOT NULL,
    asset_id integer NOT NULL,
    "position" integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sku_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sku_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sku_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sku_assets_id_seq OWNED BY sku_assets.id;


--
-- Name: sku_blog_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sku_blog_entries (
    id integer NOT NULL,
    sku_id integer NOT NULL,
    blog_entry_id integer NOT NULL
);


--
-- Name: sku_blog_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sku_blog_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sku_blog_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sku_blog_entries_id_seq OWNED BY sku_blog_entries.id;


--
-- Name: sku_price_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sku_price_logs (
    id integer NOT NULL,
    sku_id integer NOT NULL,
    price_before real,
    price_after real,
    batch_size_before bigint,
    batch_size_after bigint,
    batch_price_before real,
    batch_price_after real,
    creator_id integer,
    updater_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sku_price_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sku_price_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sku_price_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sku_price_logs_id_seq OWNED BY sku_price_logs.id;


--
-- Name: sku_stock_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sku_stock_logs (
    id integer NOT NULL,
    sku_id integer NOT NULL,
    before bigint NOT NULL,
    after bigint NOT NULL,
    action character varying(25) NOT NULL,
    creator_id integer,
    updater_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sku_stock_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sku_stock_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sku_stock_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sku_stock_logs_id_seq OWNED BY sku_stock_logs.id;


--
-- Name: skus; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE skus (
    id integer NOT NULL,
    product_id integer NOT NULL,
    product_variant_id integer,
    "position" integer DEFAULT 1 NOT NULL,
    short_desc character varying(400) NOT NULL,
    name character varying(200),
    weight integer,
    volume integer,
    size character varying(50),
    metadata hstore,
    price double precision NOT NULL,
    batch_size bigint,
    batch_price double precision,
    stock_level bigint DEFAULT 1 NOT NULL,
    status character varying(20) DEFAULT 'for_sale'::character varying NOT NULL,
    purchase_limiting boolean DEFAULT false NOT NULL,
    purchase_limit bigint,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp without time zone,
    first_published_at timestamp without time zone,
    creator_id integer NOT NULL,
    updater_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: skus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE skus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: skus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE skus_id_seq OWNED BY skus.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    email character varying(200) NOT NULL,
    encrypted_password character varying(200) NOT NULL,
    reset_password_token character varying(200),
    reset_password_sent_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY applied_promotions ALTER COLUMN id SET DEFAULT nextval('applied_promotions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_groups ALTER COLUMN id SET DEFAULT nextval('asset_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_taggings ALTER COLUMN id SET DEFAULT nextval('asset_taggings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_tags ALTER COLUMN id SET DEFAULT nextval('asset_tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assets ALTER COLUMN id SET DEFAULT nextval('assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_assets ALTER COLUMN id SET DEFAULT nextval('blog_assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_comments ALTER COLUMN id SET DEFAULT nextval('blog_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_entries ALTER COLUMN id SET DEFAULT nextval('blog_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_taggings ALTER COLUMN id SET DEFAULT nextval('blog_taggings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_tags ALTER COLUMN id SET DEFAULT nextval('blog_tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY credit_card_payments ALTER COLUMN id SET DEFAULT nextval('credit_card_payments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY credit_card_transactions ALTER COLUMN id SET DEFAULT nextval('credit_card_transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY features ALTER COLUMN id SET DEFAULT nextval('features_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY order_items ALTER COLUMN id SET DEFAULT nextval('order_items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY order_logs ALTER COLUMN id SET DEFAULT nextval('order_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY orders ALTER COLUMN id SET DEFAULT nextval('orders_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_assets ALTER COLUMN id SET DEFAULT nextval('page_assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pages ALTER COLUMN id SET DEFAULT nextval('pages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY people ALTER COLUMN id SET DEFAULT nextval('people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_assets ALTER COLUMN id SET DEFAULT nextval('product_assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_categories ALTER COLUMN id SET DEFAULT nextval('product_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ranges ALTER COLUMN id SET DEFAULT nextval('product_ranges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_variant_assets ALTER COLUMN id SET DEFAULT nextval('product_variant_assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_variants ALTER COLUMN id SET DEFAULT nextval('product_variants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY products ALTER COLUMN id SET DEFAULT nextval('products_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY promotion_conditions ALTER COLUMN id SET DEFAULT nextval('promotion_conditions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY promotion_effects ALTER COLUMN id SET DEFAULT nextval('promotion_effects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY promotions ALTER COLUMN id SET DEFAULT nextval('promotions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_assets ALTER COLUMN id SET DEFAULT nextval('sku_assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_blog_entries ALTER COLUMN id SET DEFAULT nextval('sku_blog_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_price_logs ALTER COLUMN id SET DEFAULT nextval('sku_price_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_stock_logs ALTER COLUMN id SET DEFAULT nextval('sku_stock_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY skus ALTER COLUMN id SET DEFAULT nextval('skus_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: applied_promotions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY applied_promotions
    ADD CONSTRAINT applied_promotions_pkey PRIMARY KEY (id);


--
-- Name: asset_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY asset_groups
    ADD CONSTRAINT asset_groups_pkey PRIMARY KEY (id);


--
-- Name: asset_taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY asset_taggings
    ADD CONSTRAINT asset_taggings_pkey PRIMARY KEY (id);


--
-- Name: asset_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY asset_tags
    ADD CONSTRAINT asset_tags_pkey PRIMARY KEY (id);


--
-- Name: assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: blog_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY blog_assets
    ADD CONSTRAINT blog_assets_pkey PRIMARY KEY (id);


--
-- Name: blog_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY blog_comments
    ADD CONSTRAINT blog_comments_pkey PRIMARY KEY (id);


--
-- Name: blog_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY blog_entries
    ADD CONSTRAINT blog_entries_pkey PRIMARY KEY (id);


--
-- Name: blog_taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY blog_taggings
    ADD CONSTRAINT blog_taggings_pkey PRIMARY KEY (id);


--
-- Name: blog_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY blog_tags
    ADD CONSTRAINT blog_tags_pkey PRIMARY KEY (id);


--
-- Name: credit_card_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY credit_card_payments
    ADD CONSTRAINT credit_card_payments_pkey PRIMARY KEY (id);


--
-- Name: credit_card_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY credit_card_transactions
    ADD CONSTRAINT credit_card_transactions_pkey PRIMARY KEY (id);


--
-- Name: features_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY features
    ADD CONSTRAINT features_pkey PRIMARY KEY (id);


--
-- Name: order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: order_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY order_logs
    ADD CONSTRAINT order_logs_pkey PRIMARY KEY (id);


--
-- Name: orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: page_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY page_assets
    ADD CONSTRAINT page_assets_pkey PRIMARY KEY (id);


--
-- Name: pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: product_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY product_assets
    ADD CONSTRAINT product_assets_pkey PRIMARY KEY (id);


--
-- Name: product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (id);


--
-- Name: product_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY product_ranges
    ADD CONSTRAINT product_ranges_pkey PRIMARY KEY (id);


--
-- Name: product_variant_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY product_variant_assets
    ADD CONSTRAINT product_variant_assets_pkey PRIMARY KEY (id);


--
-- Name: product_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY product_variants
    ADD CONSTRAINT product_variants_pkey PRIMARY KEY (id);


--
-- Name: products_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: promotion_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY promotion_conditions
    ADD CONSTRAINT promotion_conditions_pkey PRIMARY KEY (id);


--
-- Name: promotion_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY promotion_effects
    ADD CONSTRAINT promotion_effects_pkey PRIMARY KEY (id);


--
-- Name: promotions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY promotions
    ADD CONSTRAINT promotions_pkey PRIMARY KEY (id);


--
-- Name: sku_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sku_assets
    ADD CONSTRAINT sku_assets_pkey PRIMARY KEY (id);


--
-- Name: sku_blog_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sku_blog_entries
    ADD CONSTRAINT sku_blog_entries_pkey PRIMARY KEY (id);


--
-- Name: sku_price_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sku_price_logs
    ADD CONSTRAINT sku_price_logs_pkey PRIMARY KEY (id);


--
-- Name: sku_stock_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sku_stock_logs
    ADD CONSTRAINT sku_stock_logs_pkey PRIMARY KEY (id);


--
-- Name: skus_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY skus
    ADD CONSTRAINT skus_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_applied_promotions_on_bonus_order_item_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_applied_promotions_on_bonus_order_item_id ON applied_promotions USING btree (bonus_order_item_id);


--
-- Name: index_applied_promotions_on_order_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_applied_promotions_on_order_id ON applied_promotions USING btree (order_id);


--
-- Name: index_applied_promotions_on_promotion_effect_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_applied_promotions_on_promotion_effect_id ON applied_promotions USING btree (promotion_effect_id);


--
-- Name: index_applied_promotions_on_promotion_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_applied_promotions_on_promotion_id ON applied_promotions USING btree (promotion_id);


--
-- Name: index_applied_promotions_on_qualifying_order_item_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_applied_promotions_on_qualifying_order_item_id ON applied_promotions USING btree (qualifying_order_item_id);


--
-- Name: index_asset_groups_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_asset_groups_on_creator_id ON asset_groups USING btree (creator_id);


--
-- Name: index_asset_groups_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_asset_groups_on_updater_id ON asset_groups USING btree (updater_id);


--
-- Name: index_asset_taggings_on_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_asset_taggings_on_asset_id ON asset_taggings USING btree (asset_id);


--
-- Name: index_asset_taggings_on_asset_tag_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_asset_taggings_on_asset_tag_id ON asset_taggings USING btree (asset_tag_id);


--
-- Name: index_assets_on_asset_group_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_assets_on_asset_group_id ON assets USING btree (asset_group_id);


--
-- Name: index_assets_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_assets_on_creator_id ON assets USING btree (creator_id);


--
-- Name: index_assets_on_name_and_type_and_asset_group_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_assets_on_name_and_type_and_asset_group_id ON assets USING btree (name, type, asset_group_id);


--
-- Name: index_assets_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_assets_on_updater_id ON assets USING btree (updater_id);


--
-- Name: index_blog_assets_on_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_blog_assets_on_asset_id ON blog_assets USING btree (asset_id);


--
-- Name: index_blog_assets_on_blog_entry_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_blog_assets_on_blog_entry_id ON blog_assets USING btree (blog_entry_id);


--
-- Name: index_blog_comments_on_blog_entry_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_blog_comments_on_blog_entry_id ON blog_comments USING btree (blog_entry_id);


--
-- Name: index_blog_entries_on_author_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_blog_entries_on_author_id ON blog_entries USING btree (author_id);


--
-- Name: index_blog_entries_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_blog_entries_on_creator_id ON blog_entries USING btree (creator_id);


--
-- Name: index_blog_entries_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_blog_entries_on_updater_id ON blog_entries USING btree (updater_id);


--
-- Name: index_blog_taggings_on_blog_entry_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_blog_taggings_on_blog_entry_id ON blog_taggings USING btree (blog_entry_id);


--
-- Name: index_blog_taggings_on_blog_tag_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_blog_taggings_on_blog_tag_id ON blog_taggings USING btree (blog_tag_id);


--
-- Name: index_credit_card_payments_on_order_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_credit_card_payments_on_order_id ON credit_card_payments USING btree (order_id);


--
-- Name: index_credit_card_transactions_on_credit_card_payment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_credit_card_transactions_on_credit_card_payment_id ON credit_card_transactions USING btree (credit_card_payment_id);


--
-- Name: index_features_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_features_on_creator_id ON features USING btree (creator_id);


--
-- Name: index_features_on_page_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_features_on_page_id ON features USING btree (page_id);


--
-- Name: index_features_on_primary_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_features_on_primary_asset_id ON features USING btree (primary_asset_id);


--
-- Name: index_features_on_secondary_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_features_on_secondary_asset_id ON features USING btree (secondary_asset_id);


--
-- Name: index_features_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_features_on_updater_id ON features USING btree (updater_id);


--
-- Name: index_order_items_on_order_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_order_items_on_order_id ON order_items USING btree (order_id);


--
-- Name: index_order_items_on_sku_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_order_items_on_sku_id ON order_items USING btree (sku_id);


--
-- Name: index_order_logs_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_order_logs_on_creator_id ON order_logs USING btree (creator_id);


--
-- Name: index_order_logs_on_order_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_order_logs_on_order_id ON order_logs USING btree (order_id);


--
-- Name: index_order_logs_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_order_logs_on_updater_id ON order_logs USING btree (updater_id);


--
-- Name: index_orders_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_orders_on_creator_id ON orders USING btree (creator_id);


--
-- Name: index_orders_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_orders_on_person_id ON orders USING btree (person_id);


--
-- Name: index_orders_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_orders_on_updater_id ON orders USING btree (updater_id);


--
-- Name: index_page_assets_on_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_page_assets_on_asset_id ON page_assets USING btree (asset_id);


--
-- Name: index_page_assets_on_page_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_page_assets_on_page_id ON page_assets USING btree (page_id);


--
-- Name: index_pages_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_pages_on_creator_id ON pages USING btree (creator_id);


--
-- Name: index_pages_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_pages_on_updater_id ON pages USING btree (updater_id);


--
-- Name: index_product_assets_on_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_assets_on_asset_id ON product_assets USING btree (asset_id);


--
-- Name: index_product_assets_on_product_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_assets_on_product_id ON product_assets USING btree (product_id);


--
-- Name: index_product_categories_on_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_categories_on_asset_id ON product_categories USING btree (asset_id);


--
-- Name: index_product_categories_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_categories_on_creator_id ON product_categories USING btree (creator_id);


--
-- Name: index_product_categories_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_categories_on_updater_id ON product_categories USING btree (updater_id);


--
-- Name: index_product_ranges_on_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_ranges_on_asset_id ON product_ranges USING btree (asset_id);


--
-- Name: index_product_ranges_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_ranges_on_creator_id ON product_ranges USING btree (creator_id);


--
-- Name: index_product_ranges_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_product_ranges_on_name ON product_ranges USING btree (name);


--
-- Name: index_product_ranges_on_slug; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_product_ranges_on_slug ON product_ranges USING btree (slug);


--
-- Name: index_product_ranges_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_ranges_on_updater_id ON product_ranges USING btree (updater_id);


--
-- Name: index_product_variant_assets_on_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_variant_assets_on_asset_id ON product_variant_assets USING btree (asset_id);


--
-- Name: index_product_variant_assets_on_product_variant_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_variant_assets_on_product_variant_id ON product_variant_assets USING btree (product_variant_id);


--
-- Name: index_product_variants_on_product_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_product_variants_on_product_id ON product_variants USING btree (product_id);


--
-- Name: index_products_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_products_on_creator_id ON products USING btree (creator_id);


--
-- Name: index_products_on_name_and_product_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_products_on_name_and_product_category_id ON products USING btree (name, product_category_id);


--
-- Name: index_products_on_product_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_products_on_product_category_id ON products USING btree (product_category_id);


--
-- Name: index_products_on_product_range_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_products_on_product_range_id ON products USING btree (product_range_id);


--
-- Name: index_products_on_slug_and_product_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_products_on_slug_and_product_category_id ON products USING btree (slug, product_category_id);


--
-- Name: index_products_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_products_on_updater_id ON products USING btree (updater_id);


--
-- Name: index_promotion_conditions_on_promotion_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_promotion_conditions_on_promotion_id ON promotion_conditions USING btree (promotion_id);


--
-- Name: index_promotion_effects_on_promotion_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_promotion_effects_on_promotion_id ON promotion_effects USING btree (promotion_id);


--
-- Name: index_sku_assets_on_asset_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sku_assets_on_asset_id ON sku_assets USING btree (asset_id);


--
-- Name: index_sku_assets_on_sku_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sku_assets_on_sku_id ON sku_assets USING btree (sku_id);


--
-- Name: index_sku_blog_entries_on_blog_entry_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sku_blog_entries_on_blog_entry_id ON sku_blog_entries USING btree (blog_entry_id);


--
-- Name: index_sku_blog_entries_on_sku_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sku_blog_entries_on_sku_id ON sku_blog_entries USING btree (sku_id);


--
-- Name: index_sku_price_logs_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sku_price_logs_on_creator_id ON sku_price_logs USING btree (creator_id);


--
-- Name: index_sku_price_logs_on_sku_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sku_price_logs_on_sku_id ON sku_price_logs USING btree (sku_id);


--
-- Name: index_sku_price_logs_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sku_price_logs_on_updater_id ON sku_price_logs USING btree (updater_id);


--
-- Name: index_sku_stock_logs_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sku_stock_logs_on_creator_id ON sku_stock_logs USING btree (creator_id);


--
-- Name: index_sku_stock_logs_on_sku_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sku_stock_logs_on_sku_id ON sku_stock_logs USING btree (sku_id);


--
-- Name: index_sku_stock_logs_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sku_stock_logs_on_updater_id ON sku_stock_logs USING btree (updater_id);


--
-- Name: index_skus_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_skus_on_creator_id ON skus USING btree (creator_id);


--
-- Name: index_skus_on_product_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_skus_on_product_id ON skus USING btree (product_id);


--
-- Name: index_skus_on_product_variant_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_skus_on_product_variant_id ON skus USING btree (product_variant_id);


--
-- Name: index_skus_on_updater_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_skus_on_updater_id ON skus USING btree (updater_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: applied_promotions_bonus_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY applied_promotions
    ADD CONSTRAINT applied_promotions_bonus_order_item_id_fkey FOREIGN KEY (bonus_order_item_id) REFERENCES order_items(id);


--
-- Name: applied_promotions_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY applied_promotions
    ADD CONSTRAINT applied_promotions_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;


--
-- Name: applied_promotions_promotion_effect_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY applied_promotions
    ADD CONSTRAINT applied_promotions_promotion_effect_id_fkey FOREIGN KEY (promotion_effect_id) REFERENCES promotion_effects(id);


--
-- Name: applied_promotions_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY applied_promotions
    ADD CONSTRAINT applied_promotions_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES promotions(id);


--
-- Name: applied_promotions_qualifying_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY applied_promotions
    ADD CONSTRAINT applied_promotions_qualifying_order_item_id_fkey FOREIGN KEY (qualifying_order_item_id) REFERENCES order_items(id);


--
-- Name: asset_groups_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_groups
    ADD CONSTRAINT asset_groups_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: asset_groups_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_groups
    ADD CONSTRAINT asset_groups_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: asset_taggings_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_taggings
    ADD CONSTRAINT asset_taggings_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE;


--
-- Name: asset_taggings_asset_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_taggings
    ADD CONSTRAINT asset_taggings_asset_tag_id_fkey FOREIGN KEY (asset_tag_id) REFERENCES asset_tags(id) ON DELETE CASCADE;


--
-- Name: assets_asset_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assets
    ADD CONSTRAINT assets_asset_group_id_fkey FOREIGN KEY (asset_group_id) REFERENCES asset_groups(id) ON DELETE CASCADE;


--
-- Name: assets_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assets
    ADD CONSTRAINT assets_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: assets_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assets
    ADD CONSTRAINT assets_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: blog_assets_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_assets
    ADD CONSTRAINT blog_assets_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE;


--
-- Name: blog_assets_blog_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_assets
    ADD CONSTRAINT blog_assets_blog_entry_id_fkey FOREIGN KEY (blog_entry_id) REFERENCES blog_entries(id) ON DELETE CASCADE;


--
-- Name: blog_comments_blog_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_comments
    ADD CONSTRAINT blog_comments_blog_entry_id_fkey FOREIGN KEY (blog_entry_id) REFERENCES blog_entries(id) ON DELETE CASCADE;


--
-- Name: blog_entries_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_entries
    ADD CONSTRAINT blog_entries_author_id_fkey FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: blog_entries_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_entries
    ADD CONSTRAINT blog_entries_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: blog_entries_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_entries
    ADD CONSTRAINT blog_entries_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: blog_taggings_blog_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_taggings
    ADD CONSTRAINT blog_taggings_blog_entry_id_fkey FOREIGN KEY (blog_entry_id) REFERENCES blog_entries(id) ON DELETE CASCADE;


--
-- Name: blog_taggings_blog_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blog_taggings
    ADD CONSTRAINT blog_taggings_blog_tag_id_fkey FOREIGN KEY (blog_tag_id) REFERENCES blog_tags(id) ON DELETE CASCADE;


--
-- Name: credit_card_payments_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY credit_card_payments
    ADD CONSTRAINT credit_card_payments_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;


--
-- Name: credit_card_transactions_credit_card_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY credit_card_transactions
    ADD CONSTRAINT credit_card_transactions_credit_card_payment_id_fkey FOREIGN KEY (credit_card_payment_id) REFERENCES credit_card_payments(id) ON DELETE CASCADE;


--
-- Name: features_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY features
    ADD CONSTRAINT features_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: features_page_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY features
    ADD CONSTRAINT features_page_id_fkey FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE;


--
-- Name: features_primary_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY features
    ADD CONSTRAINT features_primary_asset_id_fkey FOREIGN KEY (primary_asset_id) REFERENCES assets(id) ON DELETE SET NULL;


--
-- Name: features_secondary_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY features
    ADD CONSTRAINT features_secondary_asset_id_fkey FOREIGN KEY (secondary_asset_id) REFERENCES assets(id) ON DELETE SET NULL;


--
-- Name: features_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY features
    ADD CONSTRAINT features_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;


--
-- Name: order_items_sku_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY order_items
    ADD CONSTRAINT order_items_sku_id_fkey FOREIGN KEY (sku_id) REFERENCES skus(id);


--
-- Name: order_logs_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY order_logs
    ADD CONSTRAINT order_logs_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: order_logs_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY order_logs
    ADD CONSTRAINT order_logs_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;


--
-- Name: order_logs_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY order_logs
    ADD CONSTRAINT order_logs_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: orders_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: orders_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE SET NULL;


--
-- Name: orders_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY orders
    ADD CONSTRAINT orders_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: page_assets_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_assets
    ADD CONSTRAINT page_assets_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE;


--
-- Name: page_assets_page_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_assets
    ADD CONSTRAINT page_assets_page_id_fkey FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE;


--
-- Name: pages_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pages
    ADD CONSTRAINT pages_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: pages_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pages
    ADD CONSTRAINT pages_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: product_assets_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_assets
    ADD CONSTRAINT product_assets_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE;


--
-- Name: product_assets_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_assets
    ADD CONSTRAINT product_assets_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;


--
-- Name: product_categories_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_categories
    ADD CONSTRAINT product_categories_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(id);


--
-- Name: product_categories_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_categories
    ADD CONSTRAINT product_categories_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: product_categories_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_categories
    ADD CONSTRAINT product_categories_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: product_ranges_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ranges
    ADD CONSTRAINT product_ranges_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(id);


--
-- Name: product_ranges_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ranges
    ADD CONSTRAINT product_ranges_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: product_ranges_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_ranges
    ADD CONSTRAINT product_ranges_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: product_variant_assets_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_variant_assets
    ADD CONSTRAINT product_variant_assets_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE;


--
-- Name: product_variant_assets_product_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_variant_assets
    ADD CONSTRAINT product_variant_assets_product_variant_id_fkey FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE;


--
-- Name: product_variants_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY product_variants
    ADD CONSTRAINT product_variants_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;


--
-- Name: products_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: products_product_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_product_category_id_fkey FOREIGN KEY (product_category_id) REFERENCES product_categories(id) ON DELETE CASCADE;


--
-- Name: products_product_range_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_product_range_id_fkey FOREIGN KEY (product_range_id) REFERENCES product_ranges(id) ON DELETE SET NULL;


--
-- Name: products_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: promotion_conditions_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY promotion_conditions
    ADD CONSTRAINT promotion_conditions_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES promotions(id) ON DELETE CASCADE;


--
-- Name: promotion_effects_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY promotion_effects
    ADD CONSTRAINT promotion_effects_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES promotions(id) ON DELETE CASCADE;


--
-- Name: sku_assets_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_assets
    ADD CONSTRAINT sku_assets_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE;


--
-- Name: sku_assets_sku_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_assets
    ADD CONSTRAINT sku_assets_sku_id_fkey FOREIGN KEY (sku_id) REFERENCES skus(id) ON DELETE CASCADE;


--
-- Name: sku_blog_entries_blog_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_blog_entries
    ADD CONSTRAINT sku_blog_entries_blog_entry_id_fkey FOREIGN KEY (blog_entry_id) REFERENCES blog_entries(id) ON DELETE CASCADE;


--
-- Name: sku_blog_entries_sku_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_blog_entries
    ADD CONSTRAINT sku_blog_entries_sku_id_fkey FOREIGN KEY (sku_id) REFERENCES skus(id) ON DELETE CASCADE;


--
-- Name: sku_price_logs_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_price_logs
    ADD CONSTRAINT sku_price_logs_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: sku_price_logs_sku_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_price_logs
    ADD CONSTRAINT sku_price_logs_sku_id_fkey FOREIGN KEY (sku_id) REFERENCES skus(id) ON DELETE CASCADE;


--
-- Name: sku_price_logs_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_price_logs
    ADD CONSTRAINT sku_price_logs_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: sku_stock_logs_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_stock_logs
    ADD CONSTRAINT sku_stock_logs_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: sku_stock_logs_sku_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_stock_logs
    ADD CONSTRAINT sku_stock_logs_sku_id_fkey FOREIGN KEY (sku_id) REFERENCES skus(id) ON DELETE CASCADE;


--
-- Name: sku_stock_logs_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sku_stock_logs
    ADD CONSTRAINT sku_stock_logs_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- Name: skus_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY skus
    ADD CONSTRAINT skus_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: skus_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY skus
    ADD CONSTRAINT skus_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;


--
-- Name: skus_product_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY skus
    ADD CONSTRAINT skus_product_variant_id_fkey FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE SET NULL;


--
-- Name: skus_updater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY skus
    ADD CONSTRAINT skus_updater_id_fkey FOREIGN KEY (updater_id) REFERENCES users(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20130116041505');

INSERT INTO schema_migrations (version) VALUES ('20130116041506');

INSERT INTO schema_migrations (version) VALUES ('20130116041507');

INSERT INTO schema_migrations (version) VALUES ('20130116041508');

INSERT INTO schema_migrations (version) VALUES ('20130116041509');

INSERT INTO schema_migrations (version) VALUES ('20130116041510');

INSERT INTO schema_migrations (version) VALUES ('20130116041511');

INSERT INTO schema_migrations (version) VALUES ('20130116041512');

INSERT INTO schema_migrations (version) VALUES ('20130116041513');

INSERT INTO schema_migrations (version) VALUES ('20130116041514');

INSERT INTO schema_migrations (version) VALUES ('20130116041515');

INSERT INTO schema_migrations (version) VALUES ('20130116041516');

INSERT INTO schema_migrations (version) VALUES ('20130116041517');

INSERT INTO schema_migrations (version) VALUES ('20130116041518');

INSERT INTO schema_migrations (version) VALUES ('20130116041519');

INSERT INTO schema_migrations (version) VALUES ('20130116041520');

INSERT INTO schema_migrations (version) VALUES ('20130116041521');

INSERT INTO schema_migrations (version) VALUES ('20130116041522');

INSERT INTO schema_migrations (version) VALUES ('20130116041523');

INSERT INTO schema_migrations (version) VALUES ('20130116041524');

INSERT INTO schema_migrations (version) VALUES ('20130116041525');

INSERT INTO schema_migrations (version) VALUES ('20130116041531');

INSERT INTO schema_migrations (version) VALUES ('20130116041532');

INSERT INTO schema_migrations (version) VALUES ('20130116041533');

INSERT INTO schema_migrations (version) VALUES ('20130116041534');

INSERT INTO schema_migrations (version) VALUES ('20130116041535');

INSERT INTO schema_migrations (version) VALUES ('20130116041536');

INSERT INTO schema_migrations (version) VALUES ('20130116041537');

INSERT INTO schema_migrations (version) VALUES ('20130116041538');

INSERT INTO schema_migrations (version) VALUES ('20130116041539');

INSERT INTO schema_migrations (version) VALUES ('20130116041540');

INSERT INTO schema_migrations (version) VALUES ('20130116041541');

INSERT INTO schema_migrations (version) VALUES ('20130116041542');

INSERT INTO schema_migrations (version) VALUES ('20130116041543');

INSERT INTO schema_migrations (version) VALUES ('20130116041544');

INSERT INTO schema_migrations (version) VALUES ('20130116041545');

INSERT INTO schema_migrations (version) VALUES ('20130116041546');

INSERT INTO schema_migrations (version) VALUES ('20130116041547');

INSERT INTO schema_migrations (version) VALUES ('20130116041548');

INSERT INTO schema_migrations (version) VALUES ('20130116041549');

INSERT INTO schema_migrations (version) VALUES ('20130116041550');

INSERT INTO schema_migrations (version) VALUES ('20130116041551');

INSERT INTO schema_migrations (version) VALUES ('20130116041552');

INSERT INTO schema_migrations (version) VALUES ('20130116041553');

INSERT INTO schema_migrations (version) VALUES ('20130117013822');

INSERT INTO schema_migrations (version) VALUES ('20130118003325');