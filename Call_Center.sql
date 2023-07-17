--- This file Contain views and Functions for Call center data-----


------Functions -------------
---Avg. Satisfaction Rating -----------
CREATE FUNCTION `AVGAgentSatisfactionRating`(agentName VARCHAR(255)) RETURNS varchar(255) CHARSET utf8mb4
    READS SQL DATA
BEGIN
    DECLARE rating VARCHAR(255);

    SELECT Avg(`Satisfaction rating`) INTO rating
    FROM `callcenter`
    WHERE Agent = agentName;

    RETURN rating;
END

-------View to find agent Performance Summary ----------

CREATE VIEW AgentCallSummary AS
SELECT Agent,
       COUNT(*) AS TotalCalls,
       SUM(CASE WHEN `Answered (Y/N)` = 'Y' THEN 1 ELSE 0 END) AS AnsweredCalls,
       SUM(CASE WHEN Resolved = 'Yes' THEN 1 ELSE 0 END) AS ResolvedCalls,
       (SUM(CASE WHEN `Answered (Y/N)` = 'Y' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS AttendancePercentage,
       (SUM(CASE WHEN Resolved = 'Yes' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS ResolvedPercentage
FROM callcenter
GROUP BY Agent;

-----Agent KPI Summary ----------

CREATE VIEW AgentSummary AS
SELECT Agent,
       AVG(CAST(`Satisfaction rating` AS DECIMAL(10, 2))) AS AvgSatisfactionRate,
       AVG(CAST(`Speed of answer in seconds` AS DECIMAL(10, 2))) AS AvgResponseTime,
       SEC_TO_TIME(SUM(TIME_TO_SEC(AvgTalkDuration))) AS TotalTalkTime
FROM callcenter
GROUP BY Agent;

