CREATE DATABASE [HixSubsetCache]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'HixSubsetCache', FILENAME = N'[locatie data file]\HixSubsetCache.mdf' , SIZE = 65536KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'HixSubsetCache_log', FILENAME = N'[locatie log file]\HixSubsetCache_log.ldf' , SIZE = 131072KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO

USE [HixSubsetCache]
GO


CREATE TABLE [dbo].[subsetAfspraakIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetDocBlobIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetDocumentIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetLabIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetMmbIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetMMBlobIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetOkIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetOpnameIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetOrderIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetPathoIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetPatientIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[subsetSehIds](
	[ID] [varchar](50) NULL
) ON [PRIMARY]
GO


