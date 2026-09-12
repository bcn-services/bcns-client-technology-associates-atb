// Volatile-line stripping and hashing, shared by verify.bat (via --strip-hash) and the fidelity checks.
// A line is dropped if it matches any regex in the volatile list; the rest are joined with '\n' and SHA-256'd.
using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace ATBRunner
{
    public static class Strip
    {
        public static List<Regex> LoadVolatile(string path)
        {
            var list = new List<Regex>();
            if (path == null || !File.Exists(path)) return list;
            foreach (var raw in File.ReadAllLines(path))
            {
                var l = raw.Trim();
                if (l.Length == 0 || l.StartsWith("#")) continue;
                list.Add(new Regex(l, RegexOptions.CultureInvariant));
            }
            return list;
        }

        public static string StrippedHash(string file, List<Regex> vol, out int total, out int dropped)
        {
            var enc = Encoding.GetEncoding("iso-8859-1");
            var lines = enc.GetString(File.ReadAllBytes(file)).Split('\n');
            var sb = new StringBuilder(); total = lines.Length; dropped = 0;
            foreach (var l in lines)
            {
                bool drop = false;
                foreach (var r in vol) if (r.IsMatch(l)) { drop = true; break; }
                if (drop) { dropped++; sb.Append("<VOLATILE>\n"); } else { sb.Append(l); sb.Append('\n'); }
            }
            using (var h = SHA256.Create()) return BitConverter.ToString(h.ComputeHash(enc.GetBytes(sb.ToString()))).Replace("-", "").ToLowerInvariant();
        }
    }
}
