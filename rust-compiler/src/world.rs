use typst::diag::FileResult;
use typst::foundations::{Bytes, Datetime, Dict, Value};
use typst::syntax::{FileId, Source};
use typst::text::{Font, FontBook};
use typst::Library;

pub struct SingleSourceWorld {
    source:     Source,
    library:    typst::utils::LazyHash<Library>,
    book:       typst::utils::LazyHash<FontBook>,
    fonts:      Vec<Font>,
    assets_dir: Option<std::path::PathBuf>,
}

impl SingleSourceWorld {
    /// Build a World whose `sys.inputs.data` is the raw JSON string from the
    /// gRPC `inputs_json` field. Templates decode it with
    /// `#let vars = json.decode(sys.inputs.at("data", default: "{}"))`.
    /// User field values are never interpolated into Typst source.
    pub fn new(typ_source: String, inputs_json: &str) -> Self {
        let assets_dir = std::env::var("TYPST_ASSETS_DIR")
            .ok()
            .map(std::path::PathBuf::from);

        let fonts: Vec<Font> = typst_assets::fonts()
            .flat_map(|data| {
                let bytes = Bytes::from_static(data);
                Font::iter(bytes)
            })
            .collect();

        let book = FontBook::from_fonts(&fonts);

        let json = if inputs_json.is_empty() { "{}" } else { inputs_json };
        let mut inputs = Dict::new();
        inputs.insert("data".into(), Value::Str(json.into()));

        Self {
            source:  Source::detached(typ_source),
            library: typst::utils::LazyHash::new(Library::builder().with_inputs(inputs).build()),
            book:    typst::utils::LazyHash::new(book),
            fonts,
            assets_dir,
        }
    }
}

impl typst::World for SingleSourceWorld {
    fn library(&self) -> &typst::utils::LazyHash<Library> {
        &self.library
    }

    fn book(&self) -> &typst::utils::LazyHash<FontBook> {
        &self.book
    }

    fn main(&self) -> FileId {
        self.source.id()
    }

    fn source(&self, id: FileId) -> FileResult<Source> {
        if id == self.source.id() {
            Ok(self.source.clone())
        } else {
            Err(typst::diag::FileError::NotFound(id.vpath().as_rootless_path().into()))
        }
    }

    fn file(&self, id: FileId) -> FileResult<Bytes> {
        let rel = id.vpath().as_rootless_path();
        if rel.components().any(|c| matches!(c, std::path::Component::ParentDir)) {
            return Err(typst::diag::FileError::AccessDenied(rel.into()));
        }
        if let Some(ref assets_dir) = self.assets_dir {
            let full_path = assets_dir.join(rel);
            let Ok(canonical) = full_path.canonicalize() else {
                return Err(typst::diag::FileError::NotFound(rel.into()));
            };
            let Ok(root) = assets_dir.canonicalize() else {
                return Err(typst::diag::FileError::NotFound(rel.into()));
            };
            if !canonical.starts_with(&root) {
                return Err(typst::diag::FileError::AccessDenied(rel.into()));
            }
            if let Ok(data) = std::fs::read(&canonical) {
                return Ok(Bytes::from(data));
            }
        }
        Err(typst::diag::FileError::NotFound(rel.into()))
    }

    fn font(&self, index: usize) -> Option<Font> {
        self.fonts.get(index).cloned()
    }

    fn today(&self, _offset: Option<i64>) -> Option<Datetime> {
        None
    }
}
