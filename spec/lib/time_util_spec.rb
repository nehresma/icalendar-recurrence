require 'spec_helper'

describe TimeUtil do
  describe ".datetime_to_time" do
    it "converts DateTime to Time correctly" do
      datetime = Icalendar::Values::DateTime.new(DateTime.parse("2014-01-27T12:55:21-08:00"))
      correct_time = Time.parse("2014-01-27T12:55:21-08:00")
      expect(TimeUtil.datetime_to_time(datetime)).to eq(correct_time)
    end

    it "converts UTC datetime to time with no offset" do
      utc_datetime = Icalendar::Values::DateTime.new(DateTime.parse("20140114T180000Z"))
      expect(TimeUtil.datetime_to_time(utc_datetime).utc_offset).to eq(0)
    end

    it "converts PST datetime to time with 8 hour offset" do
      pst_datetime = Icalendar::Values::DateTime.new(DateTime.parse("2014-01-27T12:55:21-08:00"))
      expect(TimeUtil.datetime_to_time(pst_datetime).utc_offset).to eq(-8*60*60)
    end
  end

  describe ".to_time" do
    it "uses specified timezone ID offset while converting to a Time object" do
      utc_midnight = DateTime.parse("2014-01-27T12:00:00+00:00")
      pst_midnight =     Time.parse("2014-01-27T12:00:00-08:00")

      zoned_datetime = Icalendar::Values::DateTime.new(utc_midnight, "tzid" => "America/Los_Angeles")
      
      expect(TimeUtil.to_time(zoned_datetime)).to eq(pst_midnight)
    end
  end

  describe ".date_to_time" do
    it "converts date to time object in local time" do
      local_time = Time.parse("2014-01-01")
      expect(TimeUtil.date_to_time(Date.parse("2014-01-01"))).to eq(local_time)
    end
  end

  describe "timezone_offset" do
    # Avoid DST changes by freezing time
    before { Timecop.freeze("2014-01-01") }
    after  { Timecop.return }

    it "calculates negative offset" do
      expect(TimeUtil.timezone_offset("America/Los_Angeles")).to eq("-08:00")
    end

    it "calculates positive offset" do
      expect(TimeUtil.timezone_offset("Europe/Amsterdam")).to eq("+01:00")
    end

    it "handles UTC zone" do
      expect(TimeUtil.timezone_offset("GMT")).to eq("+00:00")
    end

    it "returns nil when given an unknown timezone" do
      expect(TimeUtil.timezone_offset("Foo/Bar")).to eq(nil)      
    end

    it "removes quotes from given TZID" do
      expect(TimeUtil.timezone_offset("\"America/Los_Angeles\"")).to eq("-08:00")
    end

    it "calculates offset at a given moment" do
      after_daylight_savings = Date.parse("2014-05-01")
      expect(TimeUtil.timezone_offset("America/Los_Angeles", moment: after_daylight_savings)).to eq("-07:00")
    end

    it "handles daylight savings" do
      # FYI, clocks turn forward an hour on Nov 2 at 9:00:00 UTC
      minute_before_clocks_change = Time.parse("Nov 2 at 08:59:00 UTC") # on west coast
      minute_after_clocks_change = Time.parse("Nov 2 at 09:01:00 UTC") # on west coast

      expect(TimeUtil.timezone_offset("America/Los_Angeles", moment: minute_before_clocks_change)).to eq("-07:00")
      expect(TimeUtil.timezone_offset("America/Los_Angeles", moment: minute_after_clocks_change)).to eq("-08:00")
    end
  end
end