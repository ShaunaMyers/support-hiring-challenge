PGDMP                         z            terraform_development    12.9    12.9     �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    2270180    terraform_development    DATABASE     s   CREATE DATABASE terraform_development WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'C' LC_CTYPE = 'C';
 %   DROP DATABASE terraform_development;
                adam    false            �            1259    2270190    ar_internal_metadata    TABLE     �   CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);
 (   DROP TABLE public.ar_internal_metadata;
       public         heap    adam    false            �            1259    2270182    schema_migrations    TABLE     R   CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);
 %   DROP TABLE public.schema_migrations;
       public         heap    adam    false            �            1259    2270200    tracers    TABLE     �   CREATE TABLE public.tracers (
    id bigint NOT NULL,
    message character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);
    DROP TABLE public.tracers;
       public         heap    adam    false            �            1259    2270198    tracers_id_seq    SEQUENCE     w   CREATE SEQUENCE public.tracers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.tracers_id_seq;
       public          adam    false    205            �           0    0    tracers_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.tracers_id_seq OWNED BY public.tracers.id;
          public          adam    false    204                       2604    2270203 
   tracers id    DEFAULT     h   ALTER TABLE ONLY public.tracers ALTER COLUMN id SET DEFAULT nextval('public.tracers_id_seq'::regclass);
 9   ALTER TABLE public.tracers ALTER COLUMN id DROP DEFAULT;
       public          adam    false    204    205    205            �          0    2270190    ar_internal_metadata 
   TABLE DATA           R   COPY public.ar_internal_metadata (key, value, created_at, updated_at) FROM stdin;
    public          adam    false    203   �       �          0    2270182    schema_migrations 
   TABLE DATA           4   COPY public.schema_migrations (version) FROM stdin;
    public          adam    false    202   5       �          0    2270200    tracers 
   TABLE DATA           F   COPY public.tracers (id, message, created_at, updated_at) FROM stdin;
    public          adam    false    205   a       �           0    0    tracers_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.tracers_id_seq', 1, true);
          public          adam    false    204            "           2606    2270197 .   ar_internal_metadata ar_internal_metadata_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);
 X   ALTER TABLE ONLY public.ar_internal_metadata DROP CONSTRAINT ar_internal_metadata_pkey;
       public            adam    false    203                        2606    2270189 (   schema_migrations schema_migrations_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);
 R   ALTER TABLE ONLY public.schema_migrations DROP CONSTRAINT schema_migrations_pkey;
       public            adam    false    202            $           2606    2270208    tracers tracers_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.tracers
    ADD CONSTRAINT tracers_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.tracers DROP CONSTRAINT tracers_pkey;
       public            adam    false    205            �   =   x�K�+�,���M�+�LI-K��/ ����t��L��������P�������W� �=P      �      x�320220201�4570����� (Q|      �   8   x�3�t�,*.Q�M-.NLO�4202�5 "3#c+S3+C=3KcK#3<R\1z\\\ ��0     