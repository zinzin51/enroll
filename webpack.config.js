const path = require('path');
const nodeModulesPath = path.resolve(__dirname, 'node_modules');
const mainPath = path.resolve(__dirname, 'app/assets/typescripts');
const assetPath = path.resolve(__dirname, 'app/assets/javascripts');
const glob = require("glob");
const fs = require('fs');

const reactTemplatePath = path.resolve(__dirname, 'app/assets/typescripts/src/templates/');

module.exports = {
	entry: {
		typescripts: glob.sync(mainPath + "/src/**/*.ts?(x)")
	},
	output: {
		filename: "typescripts.js",
		path: assetPath
	},

	// Enable sourcemaps for debugging webpack's output.
	devtool: "source-map",

	resolve: {
		// Add '.ts' and '.tsx' as resolvable extensions.
		modules: [nodeModulesPath],
		extensions: [".ts", ".tsx", ".js", ".json"]
	},

	module: {
		rules: [
			// All files with a '.ts' or '.tsx' extension will be handled by 'awesome-typescript-loader'.
         		{ test: /\.tsx?$/, 
	  		  include: glob.sync(mainPath + "/src/**/*.ts?(x)"),
			  exclude: /node_modules/,
         		  loaders: [
				  "ts-loader?configFileName=./app/assets/typescripts/tsconfig.json&transpileOnly=false",
				  {    loader: "string-replace-loader",
					query: { 
						search: /reactTemplate\("([^"]*)"\)/,
						replace: function(match, p1) {
							var val = fs.readFileSync(reactTemplatePath + "/" + p1, "utf8");
							return(val);
						}
				}}]
			},
			// All output '.js' files will have any sourcemaps re-processed by 'source-map-loader'.
			{ enforce: "pre", test: /\.js$/, loader: "source-map-loader" } ]
			}

			// When importing a module whose path matches one of the following, just
			// assume a corresponding global variable exists and use that instead.
			// This is important because it allows us to avoid bundling all of our
			// dependencies, which allows browsers to cache those libraries between builds.
			/*
			   externals: {
			   "react": "React",
			   "react-dom": "ReactDOM"
			   },*/
			};
