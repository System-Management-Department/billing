<?xml version="1.0" encoding="UTF-8"?>
<stylesheet version="1.0"
	xmlns="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>
<output method="html" encoding="UTF-8" />

<template match="/">
	<html xmlns="">
		<head />
		<body>
			<table border="1" style="white-space: nowrap;border-collapse: collapse;">
				<thead>
					<tr>
						<th>伝票番号</th>
						<th>売上日付</th>
						<th>部門コード</th>
						<th>部門名</th>
						<th>チームコード</th>
						<th>チーム名</th>
						<th>当社担当者コード</th>
						<th>当社担当者名</th>
						<th>当社担当者カナ</th>
						<th>請求先コード</th>
						<th>請求先名</th>
						<th>請求先カナ</th>
						<th>請求先略式名称</th>
						<th>得意先コード</th>
						<th>得意先名</th>
						<th>得意先カナ</th>
						<th>得意先略式名称</th>
						<th>納品先</th>
						<th>件名</th>
						<th>備考</th>
						<th>支払期日</th>
						
						<th>カテゴリーコード</th>
						<th>カテゴリー名</th>
						<th>商品名</th>
						<th>単位</th>
						<th>数量</th>
						<th>単価</th>
						<th>金額</th>
						<th>発行部数</th>
					</tr>
				</thead>
				<tbody>
					<xsl:for-each select="//伝票">
						<tr>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@伝票番号" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@売上日付" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@部門コード" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@部門名" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@チームコード" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@チーム名" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@当社担当者コード" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@当社担当者名" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@当社担当者カナ" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@請求先コード" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@請求先名" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@請求先カナ" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@請求先略式名称" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@得意先コード" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@得意先名" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@得意先カナ" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@得意先略式名称" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@納品先" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@件名" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@備考" />
							</td>
							<td>
								<xsl:attribute name="rowspan"><xsl:value-of select="count(明細) + 1" /></xsl:attribute>
								<xsl:value-of select="@支払期日" />
							</td>
							<td colspan="8" style="display: none;"></td>
						</tr>
						<xsl:for-each select="明細">
							<tr>
								<td><xsl:value-of select="@カテゴリーコード" /></td>
								<td><xsl:value-of select="@カテゴリー名" /></td>
								<td><xsl:value-of select="@商品名" /></td>
								<td><xsl:value-of select="@単位" /></td>
								<td><xsl:value-of select="@数量" /></td>
								<td><xsl:value-of select="@単価" /></td>
								<td><xsl:value-of select="@金額" /></td>
								<td><xsl:value-of select="@発行部数" /></td>
							</tr>
						</xsl:for-each>
					</xsl:for-each>
				</tbody>
			</table>
		</body>
	</html>
</template>

</stylesheet>