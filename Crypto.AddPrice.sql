USE [TallPines]
GO
/****** Object:  StoredProcedure [Crypto].[AddPrice]    Script Date: 5/7/2018 9:11:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [Crypto].[AddPrice]
	@Ticker nVarChar(20),
	@Price decimal(18,8),
	@RunTime datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @Ticker = RTRIM(@Ticker)
    -- Insert statements for procedure here
	Declare @Symbol nVarchar(10) = Left(@Ticker,Len(@Ticker) - 3)
	Declare @Currency nVarchar(10) = Right(@Ticker,3)
	Declare @RollingAvg decimal (18,8)
	Declare @Slope decimal (18,8)
	Declare @Acceleration decimal (18,8)
	Declare @NewAcceleration decimal (18,8)
	Declare @Jerk decimal (18,8)
	Declare @NewJerk decimal (18,8)
	Declare @Interval decimal (18,8)	--time between samples in hours 
	Declare @Period int = 30			--Number of samples to averag over
	Declare @Velocity decimal (18,8)
	Declare @NewVelocity decimal (18,8)
	Declare @NewRollingAVG decimal (18,8)
	;

	With CalcData as (
	Select top (@Period -1)
	  	  Price
		, FIRST_VALUE(rollingAVG) over (order by stamp desc) RollingAVG
		, First_VALUE(Slope) over (order by stamp desc) Slope
		, First_VALUE(Acceleration) over (order by stamp desc) Acceleration
		, First_VALUE(Velocity) over (order by stamp desc) Velocity
		, Convert(decimal(18,8), DateDiff(second, FIRST_VALUE(SampledAt) over (order by stamp desc), @RunTime)/3600.0) Interval
	From Crypto.PriceHistory
	Where Symbol = @Symbol
	and Currency = @Currency
	Order by Stamp Desc)

	Select 
	  	  @NewRollingAvg = (sum(Price) + @Price)/@Period
		, @RollingAvg = min(RollingAVG)
		, @Slope = min(Slope)
		, @Acceleration = min(Acceleration)
		, @Velocity = min(Velocity)
		, @Interval = min(Interval)
	From CalcData
	

	Set @NewVelocity = (@NewRollingAVG - @RollingAvg)/@Interval
	Set @NewAcceleration = (@NewVelocity - @Velocity)/@Interval
	Set @NewJerk = (@NewAcceleration - @Acceleration)/@Interval

	Insert into Crypto.PriceHistory (Symbol, Currency, Price, RollingAVG, Slope, Acceleration, Jerk, SampledAt, Interval, Velocity)
		Values (@Symbol, @Currency, @Price, @NewRollingAvg, @Slope, @NewAcceleration, @NewJerk, @RunTime, @Interval, @NewVelocity)
END
