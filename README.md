# rss-converter

Convert web pages into RSS feed.

https://rss-converter.herokuapp.com/

## Example

### 渋谷区役所

https://rss-converter.herokuapp.com/rss?url=https://www.city.shibuya.tokyo.jp/news/index.html&index_selector=.js-tabTarget.is-current&article_selector=li&link_selector=a&date_selector=.date

| param | value |
|---|---|
| URL | https://www.city.shibuya.tokyo.jp/news/index.html |
| Index Selector | `.js-tabTarget.is-current` |
| Article Selector | `li` |
| Link Selector | `a` |
| Date Selector | `.date` |

### 運輸安全委員会

https://rss-converter.herokuapp.com/rss?url=https%3A%2F%2Fwww.mlit.go.jp%2Fjtsb%2F&index_selector=.news&article_selector=dl&link_selector=a&date_selector=dt

| param | value |
|---|---|
| URL | https://www.mlit.go.jp/jtsb/ |
| Index Selector | `.news` |
| Article Selector | `dl` |
| Link Selector | `a` |
| Date Selector | `dt` |
